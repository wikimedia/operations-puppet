# SPDX-License-Identifier: Apache-2.0
# @summary Set up NFS Server for the public dumps servers
class profile::dumps::distribution::nfs (
    Array[Stdlib::Host] $nfs_clients = lookup('profile::dumps::distribution::nfs_clients'),
) {
    ensure_packages(['nfs-kernel-server', 'nfs-common', 'rpcbind'])

    include network::constants
    $nfs_clients_all = $nfs_clients.wmflib::hosts2ips() + $network::constants::cloud_networks_public

    file { '/etc/default/nfs-common':
        ensure => present,
        owner  => 'root',
        group  => 'root',
        mode   => '0555',
        source => 'puppet:///modules/profile/dumps/distribution/nfs-common',
    }

    file { '/etc/default/nfs-kernel-server':
        ensure => present,
        owner  => 'root',
        group  => 'root',
        mode   => '0555',
        source => 'puppet:///modules/profile/dumps/distribution/nfs-kernel-server',
    }

    file { '/etc/modprobe.d/nfs-lockd.conf':
        ensure  => present,
        owner   => 'root',
        group   => 'root',
        mode    => '0644',
        content => 'options lockd nlm_udpport=32768 nlm_tcpport=32769',
    }

    $nfs_clients_all_formatted = $nfs_clients_all.map |$ip| {
        if $ip =~ Stdlib::IP::Address::V6 {
            # see exportfs(8) on the unique syntax it requires for IPv6
            if $ip =~ /^([^\/]+)\/(\d+)$/ {
                "[${1}]/${2}"
            } else {
                "[${ip}]"
            }
        } else {
            $ip
        }
    }

    file { '/etc/exports':
        mode    => '0444',
        owner   => 'root',
        group   => 'root',
        content => template('profile/dumps/distribution/nfs-exports.erb'),
        require => Package['nfs-kernel-server'],
        notify  => Exec['update exports'],
    }

    firewall::service { 'dumps-nfs-access':
        proto  => 'tcp',
        port   => 2049,
        srange => $nfs_clients_all,
    }

    firewall::service { 'dumps_nfs_lb_health':
        proto    => 'tcp',
        port     => [2049],
        src_sets => ['LOAD_BALANCER_HEALTH_CHECKS', 'PRODUCTION_NETWORKS'],
    }

    service { 'nfs-kernel-server':
        enable  => true,
        require => Package['nfs-kernel-server'],
    }

    exec { 'update exports':
        command     => '/usr/sbin/exportfs -ra',
        refreshonly => true,
        require     => Service['nfs-kernel-server'],
    }

    profile::auto_restarts::service { 'rpcbind':}
    profile::auto_restarts::service { 'nfs-idmapd':}
    profile::auto_restarts::service { 'nfs-blkmap':}
    profile::auto_restarts::service { 'nfs-mountd':}
}
