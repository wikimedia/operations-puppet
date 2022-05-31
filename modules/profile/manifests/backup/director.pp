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
    include profile::base::firewall

    class { 'bacula::director':
        sqlvariant          => 'mysql',
        max_dir_concur_jobs => '10',
    }

    $file_storage_production = 'FileStorageProduction'
    $file_storage_archive = 'FileStorageArchive'

    # Default pool for "normal" backups (not archivals or database-related)
    bacula::director::pool { $pool:
        max_vols         => 70,
        storage          => "${onsite_sd}-${file_storage_production}",
        volume_retention => '90 days',
        label_fmt        => $pool,
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
    bacula::director::pool { 'Archive':
        max_vols         => 5,
        storage          => "${onsite_sd}-${file_storage_archive}",
        volume_retention => '5 years',
        label_fmt        => 'archive',
        max_vol_bytes    => '536870912000',
    }

    # Databases-only pool
    bacula::director::pool { 'Databases':
        max_vols         => 95,
        storage          => "${onsite_sd}-FileStorageDatabases",
        volume_retention => '90 days',
        label_fmt        => 'databases',
        max_vol_bytes    => '536870912000',
    }
    bacula::director::pool { 'DatabasesCodfw':
        max_vols         => 95,
        storage          => "${offsite_sd}-FileStorageDatabasesCodfw",
        volume_retention => '90 days',
        label_fmt        => 'databases-codfw',
        max_vol_bytes    => '536870912000',
    }

    # Off site pool for off site backups
    bacula::director::pool { $offsite_pool:
        max_vols         => 70,
        storage          => "${offsite_sd}-${file_storage_production}",
        volume_retention => '90 days',
        label_fmt        => $offsite_pool,
        max_vol_bytes    => '536870912000',
    }

    # Eqiad pool for read-only External Storage backups
    bacula::director::pool { 'EsRoEqiad':
        max_vols         => 50,
        storage          => 'backup1003-FileStorageEsRoEqiad',
        volume_retention => '5 years',
        label_fmt        => 'es-ro-eqiad',
        max_vol_bytes    => '536870912000',
    }
    # Codfw pool for read-only External Storage backups
    bacula::director::pool { 'EsRoCodfw':
        max_vols         => 50,
        storage          => 'backup2003-FileStorageEsRoCodfw',
        volume_retention => '5 years',
        label_fmt        => 'es-ro-codfw',
        max_vol_bytes    => '536870912000',
    }
    # Eqiad pool for read-write External storage backups
    bacula::director::pool { 'EsRwEqiad':
        max_vols         => 190,
        storage          => 'backup1003-FileStorageEsRwEqiad',
        volume_retention => '90 days',
        label_fmt        => 'es-rw-eqiad',
        max_vol_bytes    => '536870912000',
    }
    # Codfw pool for read-write External storage backups
    bacula::director::pool { 'EsRwCodfw':
        max_vols         => 190,
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
    #         jobdefaults => 'Weekly-Mon-Archive',
    #     }
    # then execute 'run' on the backup director
    $one_time_backup_day = 'Mon'
    backup::weeklyjobdefaults { "Weekly-${one_time_backup_day}-Archive":
        day  => $one_time_backup_day,
        pool => 'Archive',
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
    backup::weeklyjobdefaults { "Weekly-${metadata_db_backup_day}-Databases":
        day  => $metadata_db_backup_day,
        pool => 'Databases',  # pending pool rename
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
    sudo::user { 'nagios_backup_freshness':
        ensure => absent,
    }
    nrpe::monitor_service { 'backup_freshness':
        description    => 'Backup freshness',
        nrpe_command   => '/usr/local/lib/nagios/plugins/check_bacula --icinga',
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

    ferm::service { 'bacula-director':
        proto  => 'tcp',
        port   => '9101',
        srange => '$PRODUCTION_NETWORKS',
    }
}
