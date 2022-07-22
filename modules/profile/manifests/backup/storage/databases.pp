# SPDX-License-Identifier: Apache-2.0
# Profile class for adding a storage daemon service,
# specifically, for mw metadata and misc database backups, to a host

class profile::backup::storage::databases {
    include profile::backup::storage::common

    # Databases setup:
    # 2 storage devices in a single disk array (dumps
    # and snapshots)

    file { '/srv/bacula':
        ensure => directory,
        owner  => 'bacula',
        group  => 'bacula',
        mode   => '0660',
    }
    file { [ '/srv/bacula/dumps',
          '/srv/bacula/snapshots', ]:
        ensure  => directory,
        owner   => 'bacula',
        group   => 'bacula',
        mode    => '0660',
        require => File['/srv/bacula'],
    }

    $upcase_site = capitalize($::site)
    bacula::storage::device { "FileStorageDumps${upcase_site}":
        device_type     => 'File',
        media_type      => 'File',
        archive_device  => '/srv/bacula/dumps',
        max_concur_jobs => 2,
        require         => File['/srv/bacula/dumps'],
    }
    bacula::storage::device { "FileStorageSnapshots${upcase_site}":
        device_type     => 'File',
        media_type      => 'File',
        archive_device  => '/srv/bacula/snapshots',
        max_concur_jobs => 2,
        require         => File['/srv/bacula/snapshots'],
    }
}
