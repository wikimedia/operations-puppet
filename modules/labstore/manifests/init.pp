# == class labstore
#
# This class configures the server as an NFS kernel server
# and sets the general configuration for that service, without
# actually exporting any filesystems
#

class labstore (
    $nfsd_threads = '192',
){

    require_package('nfs-kernel-server')
    require_package('lvm2')
    require_package('nfs-common')
    require_package('rpcbind')
    require_package('nfsd-ldap')

    # Nethogs is useful to monitor NFS client resource utilization
    package { 'nethogs':
        ensure => present,
    }

    $ldapincludes = ['openldap', 'nss', 'utils']
    class { 'profile::ldap::client::labs': ldapincludes => $ldapincludes }

    file { '/usr/local/sbin/snapshot-manager':
        ensure => present,
        owner  => 'root',
        group  => 'root',
        mode   => '0755',
        source => 'puppet:///modules/labstore/snapshot-manager.py',
    }

    file { '/etc/modprobe.d/nfs-lockd.conf':
        ensure  => present,
        owner   => 'root',
        group   => 'root',
        mode    => '0644',
        content => 'options lockd nlm_udpport=32768 nlm_tcpport=32769',
    }

    file { '/etc/default/nfs-common':
        ensure => present,
        owner  => 'root',
        group  => 'root',
        mode   => '0555',
        source => 'puppet:///modules/labstore/nfs-common',
    }

    file { '/etc/default/nfs-kernel-server':
        ensure  => present,
        owner   => 'root',
        group   => 'root',
        mode    => '0555',
        content => template('labstore/nfs-kernel-server.erb'),
    }
}
