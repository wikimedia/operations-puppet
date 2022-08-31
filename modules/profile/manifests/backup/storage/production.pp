# SPDX-License-Identifier: Apache-2.0
# Profile class for adding a storage daemon service to a host
# for the main production filesystem backups (everything except
# databases and wiki multimedia files)

class profile::backup::storage::production {
    include profile::backup::storage::common

    # Production setup:
    # 2 storage devices on the same mount point
    file { '/srv/bacula':
        ensure => directory,
        owner  => 'bacula',
        group  => 'bacula',
        mode   => '0660',
    }
    mount { '/srv/bacula' :
        ensure  => mounted,
        device  => '/dev/mapper/hwraid-backups',
        fstype  => 'ext4',
        require => File['/srv/bacula'],
    }
    file { [ '/srv/bacula/production',
          '/srv/bacula/archive' ]:
        ensure  => directory,
        owner   => 'bacula',
        group   => 'bacula',
        mode    => '0660',
        require => Class['bacula::storage'],
    }

    $upcase_site = capitalize($::site)
    bacula::storage::device { "FileStorageArchive${upcase_site}":
        device_type     => 'File',
        media_type      => 'File',
        archive_device  => '/srv/bacula/archive',
        max_concur_jobs => 2,
    }
    bacula::storage::device { "FileStorageProduction${upcase_site}":
        device_type     => 'File',
        media_type      => 'File',
        archive_device  => '/srv/bacula/production',
        max_concur_jobs => 2,
    }
}
