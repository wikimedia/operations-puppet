# = Class: labs_storage::server
#
# This puts in all the replication master code required by
# labs_storage::snapshot and labs_storage::replication
# resources.
#
# All storage servers should have this, even if they are not
# currently replicating, so this might be a good spot to add
# monitoring or configuration common to all of them regardless
# of whether they are the currently active one or not.
#

class labs_storage::server {

    file { '/etc/replication-rsync.conf':
        ensure  => present,
        owner   => 'root',
        group   => 'root',
        mode    => '0444',
        source  => 'puppet:///modules/labs_storage/replication-rsync.conf',
    }

    file { '/usr/local/sbin/manage-snapshots':
        ensure  => present,
        owner   => 'root',
        group   => 'root',
        mode    => '0555',
        source  => 'puppet:///modules/labs_storage/manage-snapshots',
    }

    file { '/usr/local/sbin/storage-replicate':
        ensure  => present,
        owner   => 'root',
        group   => 'root',
        mode    => '0555',
        source  => 'puppet:///modules/labs_storage/storage-replicate',
        require => File['/etc/replication-rsync.conf'],
    }

    # We do not include ldap::client here because it brings in
    # complete auth for LDAP users intended for labs instances.
    #
    # Rather, we include the configuration, then explicitly set up
    # a minimalist configuration that is just sufficient to
    # bring in the (redacted) list of users and groups for NFS
    # permission checks, without setting up or permitting any
    # authentication or session setup for those users.

    include ldap::role::config::labs

    file { '/etc/nsswitch.conf':
        source => 'puppet:///modules/labs_storage/nsswitch.conf',
    }

    package { 'nslcd':
        ensure => present,
    }

    file { '/etc/nslcd.conf':
        notify  => Service['nslcd'],
        owner   => 'root',
        group   => 'root',
        mode    => '0440',
        content => template('labs_storage/nslcd.conf.erb'),
    }

    service { 'nslcd':
        ensure  => running,
        require => [ Package['nslcd'], File['/etc/nslcd.conf'], ],
    }

}

