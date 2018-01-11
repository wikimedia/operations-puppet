# Set up NFS Server for the public dumps servers
# Firewall rules are managed separately through profile::wmcs::nfs::ferm

class profile::dumps::distribution::nfs {

    require_package('nfs-kernel-server', 'nfs-common', 'rpcbind')

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

    file { '/etc/exports':
        mode    => '0444',
        owner   => 'root',
        group   => 'root',
        source  => 'puppet:///modules/profile/dumps/distribution/nfs-exports',
        require => Package['nfs-kernel-server'],
    }

    # Manage state manually
    service { 'nfs-kernel-server':
        enable  => false,
        require => Package['nfs-kernel-server'],
    }

}
