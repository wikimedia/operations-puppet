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

    class { 'bacula::storage':
        director           => $director,
        sd_max_concur_jobs => 5,
        sqlvariant         => 'mysql',
    }

    # We have two storage devices to overcome any limitations from backend
    # infrastructure (e.g. Netapp used to have only < 16T volumes)
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
