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
        ensure  => file,
        owner   => 'root',
        group   => 'root',
        mode    => '0444',
        source  => 'puppet:///modules/labs_storage/replication-rsync.conf',
    }

    file { '/usr/local/sbin/manage-snapshots':
        ensure  => file,
        owner   => 'root',
        group   => 'root',
        mode    => '0555',
        source  => 'puppet:///modules/labs_storage/manage-snapshots',
    }

    file { '/usr/local/sbin/storage-replicate':
        ensure  => file,
        owner   => 'root',
        group   => 'root',
        mode    => '0555',
        source  => 'puppet:///modules/labs_storage/storage-replicate',
        require => File['/etc/replication-rsync.conf'],
    }

    # In order to have permissions work properly both when serving
    # NFS and when replicating with rsync, the users and their group
    # membership needs to be known to the server.  This requires
    # grabbing the information from LDAP (which is the authoritative
    # source) without conflicting with actual system users.  In order
    # to do that we need to use nslcd but:
    #  (a) do not configure PAM to auth against it;
    #  (b) alter the entries so that the usernames are actually
    #      user *ids* and thus cannot conflict with puppet-managed
    #      users; and
    #  (c) make sure that imported users have no valid shell

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

