class role::backup::storage() {
    include role::backup::config
    include ::base::firewall

    system::role { 'role::backup::storage': description => 'Backup Storage' }

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
        director           => $role::backup::config::director,
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
    }

    ferm::service { 'bacula-storage-demon':
        proto  => 'tcp',
        port   => '9103',
        srange => '$PRODUCTION_NETWORKS',
    }
}
