# Profile class for adding a storage daemon service to a host

class profile::backup::storage::main {
    include profile::backup::storage::common

    # Main setup:
    # 3 storage devices separated on 2 physical arrays
    mount { '/srv/archive' :
        ensure  => mounted,
        device  => '/dev/mapper/array1-archive',
        fstype  => 'ext4',
        require => File['/srv/archive'],
    }
    mount { '/srv/production' :
        ensure  => mounted,
        device  => '/dev/mapper/array1-production',
        fstype  => 'ext4',
        require => File['/srv/production'],
    }
    mount { '/srv/databases' :
        ensure  => mounted,
        device  => '/dev/mapper/array2-databases',
        fstype  => 'ext4',
        require => File['/srv/databases'],
    }
    file { ['/srv/archive',
            '/srv/production',
            '/srv/databases', ]:
        ensure  => directory,
        owner   => 'bacula',
        group   => 'bacula',
        mode    => '0660',
        require => Class['bacula::storage'],
    }

    bacula::storage::device { 'FileStorageArchive':
        device_type     => 'File',
        media_type      => 'File',
        archive_device  => '/srv/archive',
        max_concur_jobs => 2,
    }
    bacula::storage::device { 'FileStorageProduction':
        device_type     => 'File',
        media_type      => 'File',
        archive_device  => '/srv/production',
        max_concur_jobs => 2,
    }
    if $::site == 'eqiad' {
        bacula::storage::device { 'FileStorageDatabases':
            device_type     => 'File',
            media_type      => 'File',
            archive_device  => '/srv/databases',
            max_concur_jobs => 2,
        }
    } elsif $::site == 'codfw' {
        bacula::storage::device { 'FileStorageDatabasesCodfw':
            device_type     => 'File',
            media_type      => 'File',
            archive_device  => '/srv/databases',
            max_concur_jobs => 2,
        }
    } else {
        fail('Only eqiad or codfw pools are configured for database backups.')
    }
}
