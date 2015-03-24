

class labs_storage::server
{
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

