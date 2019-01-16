# Configures a WMCS NFS server (only tested on Stretch)

class profile::wmcs::nfs::server (
    Integer $nfsd_threads = lookup('profile::wmcs::nfs::server::nfsd_threads'),
) {
    $packages = [
        'lvm2',
        'nethogs',
        'nfs-common',
        'nfs-kernel-server',
        'nfsd-ldap',
        'rpcbind',
    ]

    package { $packages:
        ensure => 'present',
    }

    $ldapincludes = ['openldap', 'nss', 'utils']
    class { 'profile::ldap::client::labs': ldapincludes => $ldapincludes }

    file { '/usr/share/base-files/nsswitch.conf':
        ensure => present,
        owner  => 'root',
        group  => 'root',
        mode   => '0644',
        source => 'puppet:///modules/profile/wmcs/nfs/server/nsswitch.conf',
    }

    file { '/usr/local/sbin/snapshot-manager':
        ensure => present,
        owner  => 'root',
        group  => 'root',
        mode   => '0755',
        source => 'puppet:///modules/profile/wmcs/nfs/server/snapshot-manager.py',
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
        source => 'puppet:///modules/profile/wmcs/nfs/server/nfs-common',
    }

    file { '/etc/default/nfs-kernel-server':
        ensure  => present,
        owner   => 'root',
        group   => 'root',
        mode    => '0555',
        content => template('profile/wmcs/nfs/server/nfs-kernel-server.erb'),
    }
}
