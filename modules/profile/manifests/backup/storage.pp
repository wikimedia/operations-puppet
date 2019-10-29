# Profile class for adding backup director functionalities to a host
#
# Note that of hiera key lookups have a name space of profile::backup instead
# of profile::backup::director. That's cause they are reused in other profile
# classes in the same hierarchy and is consistent with our code guidelines
class profile::backup::storage(
    $director = hiera('profile::backup::director'),
) {
    include ::profile::base::firewall
    include ::profile::standard


    class { 'bacula::storage':
        director           => $director,
        sd_max_concur_jobs => 5,
        sqlvariant         => 'mysql',
    }

    # Temporary conditional to handle the 2 separate storage layouts

    if os_version('debian >= buster') {
        # TODO: Remove once all jessies are gone
        # Downgrade TLS from 1.2 to 1
        file { '/etc/ssl/openssl.cnf':
            ensure => present,
            owner  => 'root',
            group  => 'root',
            mode   => '0644',
            source => 'puppet:///modules/profile/backup/openssl.cnf',
        }

        # New setup:
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
        bacula::storage::device { 'FileStorageDatabases':
            device_type     => 'File',
            media_type      => 'File',
            archive_device  => '/srv/databases',
            max_concur_jobs => 2,
        }
    } else {
        # Legacy setup (to be decommissioned):
        # We have two storage devices to overcome any limitations from backend
        # infrastructure (e.g. Netapp used to have only < 16T volumes)
        mount { '/srv/baculasd1' :
            ensure  => mounted,
            device  => '/dev/mapper/bacula-baculasd1',
            fstype  => 'ext4',
            require => File['/srv/baculasd1'],
        }

        mount { '/srv/baculasd2' :
            ensure  => mounted,
            device  => '/dev/mapper/bacula-baculasd2',
            fstype  => 'ext4',
            require => File['/srv/baculasd2'],
        }
        file { ['/srv/baculasd1',
                '/srv/baculasd2' ]:
            ensure  => directory,
            owner   => 'bacula',
            group   => 'bacula',
            mode    => '0660',
            require => Class['bacula::storage'],
        }

        bacula::storage::device { 'FileStorage1':
            device_type     => 'File',
            media_type      => 'File',
            archive_device  => '/srv/baculasd1',
            max_concur_jobs => 2,
        }

        bacula::storage::device { 'FileStorage2':
            device_type     => 'File',
            media_type      => 'File',
            archive_device  => '/srv/baculasd2',
            max_concur_jobs => 2,
        }
    }
    nrpe::monitor_service { 'bacula_sd':
        description  => 'bacula sd process',
        nrpe_command => '/usr/lib/nagios/plugins/check_procs -w 1:1 -c 1:1 -u bacula -C bacula-sd',
        notes_url    => 'https://wikitech.wikimedia.org/wiki/Bacula',
    }

    ferm::service { 'bacula-storage-demon':
        proto  => 'tcp',
        port   => '9103',
        srange => '$PRODUCTION_NETWORKS',
    }
}
