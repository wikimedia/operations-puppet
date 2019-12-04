# Profile class for adding backup director functionalities to a host
#
# Note that SOME of hiera key lookups have a name space of profile::backup instead
# of profile::backup::director. That's cause they are reused in other profile
# classes in the same hierarchy and is consistent with our code guidelines
class profile::backup::director(
    $pool = hiera('profile::backup::pool'),
    $days = hiera('profile::backup::days'),
    $offsite_pool = hiera('profile::backup::director::offsite_pool'),
    $onsite_sd = hiera('profile::backup::director::onsite_sd'),
    $offsite_sd = hiera('profile::backup::director::offsite_sd'),
    $dbhost = hiera('profile::backup::director::dbhost'),
    $dbschema = hiera('profile::backup::director::dbschema'),
    $dbport = hiera('profile::backup::director::dbport'),
    $dbuser = hiera('profile::backup::director::dbuser'),
    $dbpass = hiera('profile::backup::director::dbpass'),
    $prometheus_nodes = hiera('prometheus_nodes'),
){
    include ::profile::base::firewall

    class { 'bacula::director':
        sqlvariant          => 'mysql',
        max_dir_concur_jobs => '10',
    }

    if os_version('debian >= buster') {
        $file_storage_production = 'FileStorageProduction'
        $file_storage_archive = 'FileStorageArchive'
        $file_storage_databases = 'FileStorageDatabases'
        $scheduled_pools = [ $pool, 'Databases', ]
    } else {
        $file_storage_production = 'FileStorage1'
        $file_storage_archive = 'FileStorage2'
        $scheduled_pools = [ $pool, ]
    }

    # One pool for all, except databases
    bacula::director::pool { $pool:
        max_vols         => 60,
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
    if os_version('debian >= buster') {
        bacula::director::pool { 'Databases':
            max_vols         => 60,
            storage          => "${onsite_sd}-${file_storage_databases}",
            volume_retention => '90 days',
            label_fmt        => 'databases',
            max_vol_bytes    => '536870912000',
        }
    }

    # Off site pool for off site backups
    bacula::director::pool { $offsite_pool:
        max_vols         => 60,
        storage          => "${offsite_sd}-${file_storage_production}",
        volume_retention => '30 days',
        label_fmt        => $offsite_pool,
        max_vol_bytes    => '536870912000',
    }

    # One schedule per day of the week.
    # Setting execution times so that it is unlikely jobs will run concurrently
    # with cron.{hourly,daily,monthly} or other cronscripts
    $days.each |String $day| {
        # monthly
        backup::monthlyschedule { $day:  # schedules are pool-independent
            day => $day,
        }
        $scheduled_pools.each |String $scheduled_pool| {
            backup::monthlyjobdefaults { "${scheduled_pool}-${day}":
                day  => $day,
                pool => $scheduled_pool,
            }
        }
        # weekly
        backup::weeklyschedule { $day:
            day => $day,
        }
        $scheduled_pools.each |String $scheduled_pool| {
            backup::weeklyjobdefaults { "${scheduled_pool}-${day}":
                day  => $day,
                pool => $scheduled_pool,
            }
        }
        # hourly
        backup::hourlyschedule { $day:
            day => $day,
        }
        $scheduled_pools.each |String $scheduled_pool| {
            backup::hourlyjobdefaults { "${scheduled_pool}-${day}":
                day  => $day,
                pool => $scheduled_pool,
            }
        }
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
        director   => $::fqdn,
    }

    nrpe::monitor_service { 'bacula_director':
        description  => 'bacula director process',
        nrpe_command => '/usr/lib/nagios/plugins/check_procs -w 1:1 -c 1:1 -u bacula -C bacula-dir',
        notes_url    => 'https://wikitech.wikimedia.org/wiki/Bacula',
    }

    # install the general backup check and set it up to run every hour
    class { 'bacula::director::check': }
    ::sudo::user { 'nagios_backup_freshness':
        user       => 'nagios',
        privileges => ['ALL = (bacula) NOPASSWD: /usr/bin/check_bacula.py'],
    }
    nrpe::monitor_service { 'backup_freshness':
        description    => 'Backup freshness',
        nrpe_command   => '/usr/bin/sudo -u bacula /usr/bin/check_bacula.py',
        critical       => false,
        contact_group  => 'admins',
        check_interval => 60,  # check every hour
        timeout        => 60,  # 1 minute of timeout, the check is not fast
        notes_url      => 'https://wikitech.wikimedia.org/wiki/Backups#Monitoring',
    }

    # install the prometheus exporter for bacula
    class { 'bacula::director::prometheus_exporter':
        port => '9133',
    }
    base::service_auto_restart { 'prometheus-bacula-exporter': }

    ferm::service { 'bacula-director':
        proto  => 'tcp',
        port   => '9101',
        srange => '$PRODUCTION_NETWORKS',
    }
    $prometheus_nodes_ferm = join($prometheus_nodes, ' ')
    ferm::service { 'bacula-prometheus-exporter':
        proto  => 'tcp',
        port   => '9133',
        srange => "@resolve((${prometheus_nodes_ferm}))",
    }
}
