# Profile class for adding backup director functionalities to a host
#
# Note that SOME of hiera key lookups have a name space of profile::backup instead
# of profile::backup::director. That's cause they are reused in other profile
# classes in the same hierarchy and is consistent with our code guidelines
class profile::backup::director(
    String              $pool             = lookup('profile::backup::pool'),
    Array[String]       $days             = lookup('profile::backup::days'),
    String              $offsite_pool     = lookup('profile::backup::director::offsite_pool'),
    String              $onsite_sd        = lookup('profile::backup::director::onsite_sd'),
    String              $offsite_sd       = lookup('profile::backup::director::offsite_sd'),
    Stdlib::Host        $dbhost           = lookup('profile::backup::director::dbhost'),
    String              $dbschema         = lookup('profile::backup::director::dbschema'),
    Stdlib::Port        $dbport           = lookup('profile::backup::director::dbport'),
    String              $dbuser           = lookup('profile::backup::director::dbuser'),
    String              $dbpass           = lookup('profile::backup::director::dbpass'),
){
    include profile::firewall

    class { 'bacula::director':
        sqlvariant          => 'mysql',
        max_dir_concur_jobs => '10',
    }

    # FIXME: When we do multisite, these should be handled better
    $file_storage_production = 'FileStorageProductionEqiad'
    $file_storage_archive = 'FileStorageArchiveEqiad'

    # Default pool for "normal" backups (not archivals or database-related)
    bacula::director::pool { $pool:
        max_vols         => 150,
        storage          => "${onsite_sd}-${file_storage_production}",
        volume_retention => '90 days',
        label_fmt        => $pool,
        max_vol_bytes    => '536870912000',
    }
    # old production pool, to be removed in 60 days
    bacula::director::pool { 'OldProduction':
        max_vols         => 70,
        storage          => 'backup1001-FileStorageProduction',
        volume_retention => '90 days',
        label_fmt        => 'production',
        max_vol_bytes    => '536870912000',
        next_pool        => $offsite_pool,
    }

    # Default pool needed internally by bacula
    bacula::director::pool { 'Default':
        max_vols         => 1,
        storage          => "${onsite_sd}-${file_storage_production}",
        volume_retention => '1800 days',
    }

    # Archive pool for long term archival.
    bacula::director::pool { 'ArchiveEqiad':
        max_vols         => 5,
        storage          => "${onsite_sd}-${file_storage_archive}",
        volume_retention => '5 years',
        label_fmt        => 'archiveEqiad',
        max_vol_bytes    => '536870912000',
    }

    # Old Archive pool for long term archival - to be removed when migrated to the above
    bacula::director::pool { 'OldArchive':
        max_vols         => 5,
        storage          => 'backup1001-FileStorageArchive',
        volume_retention => '5 years',
        label_fmt        => 'archive',
        max_vol_bytes    => '536870912000',
    }

    # TODO: This will probably be later a per-dc hiera key
    $databases_sd_eqiad = 'backup1008'
    $databases_sd_codfw = 'backup2008'
    # Database dumps-only pool
    bacula::director::pool { 'DatabasesEqiad':
        max_vols         => 95,  # increase if size > 50 TB
        storage          => "${databases_sd_eqiad}-FileStorageDumpsEqiad",
        volume_retention => '90 days',
        label_fmt        => 'databases-eqiad',
        max_vol_bytes    => '536870912000',
    }
    bacula::director::pool { 'DatabasesCodfw':
        max_vols         => 95,  # increase if size > 50 TB
        storage          => "${databases_sd_codfw}-FileStorageDumpsCodfw",
        volume_retention => '90 days',
        label_fmt        => 'databases-codfw',
        max_vol_bytes    => '536870912000',
    }
    # Old databases pool, kept as read-only (for recovery purposes only).
    # Temporary, to be removed after 60 days pass.
    bacula::director::pool { 'OldDatabasesEqiad':
        max_vols         => 95,
        storage          => 'backup1001-FileStorageDatabases',
        volume_retention => '90 days',
        label_fmt        => 'databases',
        max_vol_bytes    => '536870912000',
    }
    bacula::director::pool { 'OldDatabasesCodfw':
        max_vols         => 95,
        storage          => 'backup2001-FileStorageDatabasesCodfw',
        volume_retention => '90 days',
        label_fmt        => 'databases-codfw',
        max_vol_bytes    => '536870912000',
    }


    # TODO: config codfw pool when there is dual directors
    # Off site pool for off site backups
    bacula::director::pool { $offsite_pool:
        max_vols         => 70,
        storage          => "${offsite_sd}-FileStorageProduction",
        volume_retention => '90 days',
        label_fmt        => $offsite_pool,
        max_vol_bytes    => '536870912000',
    }

    # Eqiad pool for read-only External Storage backups
    bacula::director::pool { 'EsRoEqiad':
        max_vols         => 100,
        storage          => 'backup1003-FileStorageEsRoEqiad',
        volume_retention => '5 years',
        label_fmt        => 'es-ro-eqiad',
        max_vol_bytes    => '536870912000',
    }
    # Codfw pool for read-only External Storage backups
    bacula::director::pool { 'EsRoCodfw':
        max_vols         => 100,
        storage          => 'backup2003-FileStorageEsRoCodfw',
        volume_retention => '5 years',
        label_fmt        => 'es-ro-codfw',
        max_vol_bytes    => '536870912000',
    }
    # Eqiad pool for read-write External storage backups
    bacula::director::pool { 'EsRwEqiad':
        max_vols         => 200,
        storage          => 'backup1003-FileStorageEsRwEqiad',
        volume_retention => '90 days',
        label_fmt        => 'es-rw-eqiad',
        max_vol_bytes    => '536870912000',
    }
    # Codfw pool for read-write External storage backups
    bacula::director::pool { 'EsRwCodfw':
        max_vols         => 200,
        storage          => 'backup2003-FileStorageEsRwCodfw',
        volume_retention => '90 days',
        label_fmt        => 'es-rw-codfw',
        max_vol_bytes    => '536870912000',
    }

    # Predefined schedules
    $days.each |String $day| {
        # monthly
        backup::monthlyschedule { $day:  # schedules are pool-independent
            day => $day,
        }
        # weekly
        backup::weeklyschedule { $day:
            day => $day,
        }
        # hourly
        backup::hourlyschedule { $day:
            day => $day,
        }
    }
    # daily (does not require a day)
    backup::dailyschedule {'Daily': }

    # Predefined jobdefaults for the default pool.
    $days.each |String $day| {
        # monthly
        backup::monthlyjobdefaults { "${pool}-${day}":
            day  => $day,
            pool => $pool,
        }
        backup::weeklyjobdefaults { "${pool}-${day}":
            day  => $day,
            pool => $pool,
        }
        backup::hourlyjobdefaults { "${pool}-${day}":
            day  => $day,
            pool => $pool,
        }
    }

    # Jobdefaults ready for one time Archive-like backups
    # Use it like this on a profile:
    #     backup::set { '<set-of-files-and-dirs-name>':
    #         jobdefaults => 'Weekly-Mon-ArchiveEqiad',
    #     }
    # then execute 'run' on the backup director
    $one_time_backup_day = 'Mon'
    backup::weeklyjobdefaults { "Weekly-${one_time_backup_day}-ArchiveEqiad":
        day  => $one_time_backup_day,
        pool => 'ArchiveEqiad',
    }
    # jobdefaults ready for one time ro backups
    backup::weeklyjobdefaults { "Weekly-${one_time_backup_day}-EsRoEqiad":
        day  => $one_time_backup_day,
        pool => 'EsRoEqiad',
    }
    backup::weeklyjobdefaults { "Weekly-${one_time_backup_day}-EsRoCodfw":
        day  => $one_time_backup_day,
        pool => 'EsRoCodfw',
    }

    # Jobdefaults for metadata Database backups
    $metadata_db_backup_day = 'Wed'
    backup::weeklyjobdefaults { "Weekly-${metadata_db_backup_day}-DatabasesEqiad":
        day  => $metadata_db_backup_day,
        pool => 'DatabasesEqiad',
    }
    backup::weeklyjobdefaults { "Weekly-${metadata_db_backup_day}-DatabasesCodfw":
        day  => $metadata_db_backup_day,
        pool => 'DatabasesCodfw',
    }
    $es_db_backup_day = 'Thu'
    backup::weeklyjobdefaults { "Weekly-${es_db_backup_day}-EsRwEqiad":
        day  => $es_db_backup_day,
        pool => 'EsRwEqiad',
    }
    backup::weeklyjobdefaults { "Weekly-${es_db_backup_day}-EsRwCodfw":
        day  => $es_db_backup_day,
        pool => 'EsRwCodfw',
    }

    # Jobdefaults for Gitlab (full backups every day)
    backup::dailyjobdefaults { "Daily-${pool}":
        pool => $pool,
    }

    bacula::director::catalog { 'production':
        dbname     => $dbschema,
        dbuser     => $dbuser,
        dbhost     => $dbhost,
        dbport     => $dbport,
        dbpassword => $dbpass,
    }

    # The console should be on the director
    class { 'bacula::console':
        director   => $facts['fqdn'],
    }

    nrpe::monitor_service { 'bacula_director':
        description  => 'bacula director process',
        nrpe_command => '/usr/lib/nagios/plugins/check_procs -w 1:1 -c 1:1 -u bacula -C bacula-dir',
        notes_url    => 'https://wikitech.wikimedia.org/wiki/Bacula#Monitoring',
    }

    # install the general backup check and set it up to run every hour
    class { 'bacula::director::check': }

    nrpe::monitor_service { 'backup_freshness':
        description    => 'Backup freshness',
        nrpe_command   => '/usr/bin/check_bacula.py --icinga',
        sudo_user      => 'bacula',
        critical       => false,
        contact_group  => 'admins',
        check_interval => 60,  # check every hour
        timeout        => 60,  # 1 minute of timeout, the check is not fast
        notes_url      => 'https://wikitech.wikimedia.org/wiki/Bacula#Monitoring',
    }

    # install the prometheus exporter for bacula
    class { 'bacula::director::prometheus_exporter':
        port => '9133',
    }
    profile::auto_restarts::service { 'prometheus-bacula-exporter': }

    file { '/etc/bacula/job_monitoring_ignorelist':
        ensure => present,
        source => 'puppet:///modules/profile/backup/job_monitoring_ignorelist',
        owner  => 'bacula',
        group  => 'bacula',
        mode   => '0550',
    }

    firewall::service { 'bacula-director':
        proto    => 'tcp',
        port     => 9101,
        src_sets => ['PRODUCTION_NETWORKS'],
    }
}
