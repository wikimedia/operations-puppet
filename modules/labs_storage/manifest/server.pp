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

    file { '/usr/local/sbin/storage-snapshot':
        ensure  => file,
        owner   => 'root',
        group   => 'root',
        mode    => '0555',
        source  => 'puppet:///modules/labs_storage/storage-snapshot',
        require => File['/usr/local/sbin/manage-snapshots'],
    }

}

