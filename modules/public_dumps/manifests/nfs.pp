# Set up NFS Server for the public dumps servers
# Firewall rules are managed separately through profile::wmcs::nfs::ferm

class public_dumps::nfs {

    require_package('nfs-kernel-server', 'nfs-common', 'rpcbind')

    file { '/etc/default/nfs-common':
        ensure => present,
        owner  => 'root',
        group  => 'root',
        mode   => '0555',
        source => 'puppet:///modules/public_dumps/nfs-common',
    }

    file { '/etc/default/nfs-kernel-server':
        ensure => present,
        owner  => 'root',
        group  => 'root',
        mode   => '0555',
        source => 'puppet:///modules/public_dumps/nfs-kernel-server',
    }

    file { '/etc/modprobe.d/nfs-lockd.conf':
        ensure  => present,
        owner   => 'root',
        group   => 'root',
        mode    => '0644',
        content => 'options lockd nlm_udpport=32768 nlm_tcpport=32769',
    }

    # Manage state manually
    service { 'nfs-kernel-server':
        enable => false,
    }

}
