# Profile class for adding a storage daemon service,
# specifically, for External Storage backups, to a host

class profile::backup::storage::es {
    include profile::backup::storage::common

    # External Storage setup:
    # 2 storage devices in a single disk array (read-only
    # and read-write backups)

    file { '/srv/bacula':
        ensure => directory,
        owner  => 'bacula',
        group  => 'bacula',
        mode   => '0660',
    }
    file { [ '/srv/bacula/es-readonly',
          '/srv/bacula/es-readwrite', ]:
        ensure  => directory,
        owner   => 'bacula',
        group   => 'bacula',
        mode    => '0660',
        require => File['/srv/bacula'],
    }

    $upcase_site = capitalize($::site)
    bacula::storage::device { "FileStorageEsRo${upcase_site}":
        device_type     => 'File',
        media_type      => 'File',
        archive_device  => '/srv/bacula/es-readonly',
        max_concur_jobs => 2,
        require         => File['/srv/bacula/es-readonly'],
    }
    bacula::storage::device { "FileStorageEsRw${upcase_site}":
        device_type     => 'File',
        media_type      => 'File',
        archive_device  => '/srv/bacula/es-readwrite',
        max_concur_jobs => 2,
        require         => File['/srv/bacula/es-readwrite'],
    }
}
