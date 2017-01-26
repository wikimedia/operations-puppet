# == class labstore
#
# This class configures the server as an NFS kernel server
# and sets the general configuration for that service, without
# actually exporting any filesystems
#

class labstore {

    require_package('nfs-kernel-server')
    require_package('lvm2')
    require_package('nfsd-ldap')

    $ldapincludes = ['openldap', 'nss', 'utils']
    class { '::ldap::role::client::labs': ldapincludes => $ldapincludes }

    file { '/usr/local/sbin/snapshot-manager':
        ensure => present,
        owner  => 'root',
        group  => 'root',
        mode   => '0755',
        source => 'puppet:///modules/labstore/snapshot-manager.py',
    }

    file { '/etc/default/nfs-common':
        ensure => present,
        owner  => 'root',
        group  => 'root',
        mode   => '0555',
        source => 'puppet:///modules/labstore/nfs-common',
    }

    file { '/etc/default/nfs-kernel-server':
        ensure => present,
        owner  => 'root',
        group  => 'root',
        mode   => '0555',
        source => 'puppet:///modules/labstore/nfs-kernel-server',
    }
}
