class role::backup::director {
    include role::backup::host
    include role::backup::config
    include passwords::bacula
    require geowiki::params
    $pool = $role::backup::config::pool
    $offsite_pool = $role::backup::config::offsite_pool
    $onsite_sd = $role::backup::config::onsite_sd
    $offsite_sd = $role::backup::config::offsite_sd

    system::role { 'role::backup::director': description => 'Backup server' }

    class { 'bacula::director':
        sqlvariant          => 'mysql',
        max_dir_concur_jobs => '10',
    }

    # One pool for all
    bacula::director::pool { $pool:
        max_vols         => 50,
        storage          => "${onsite_sd}-FileStorage1",
        volume_retention => '60 days',
        label_fmt        => $pool,
        max_vol_bytes    => '536870912000',
        next_pool        => $offsite_pool,
    }

    # Default pool needed internally by bacula
    bacula::director::pool { 'Default':
        max_vols         => 1,
        storage          => "${onsite_sd}-FileStorage1",
        volume_retention => '1800 days',
    }

    # Archive pool for long term archival.
    bacula::director::pool { 'Archive':
        max_vols         => 5,
        storage          => "${onsite_sd}-FileStorage2",
        volume_retention => '5 years',
        label_fmt        => 'archive',
        max_vol_bytes    => '536870912000',
    }

    # Off site pool for off site backups
    bacula::director::pool { $offsite_pool:
        max_vols         => 50,
        storage          => "${offsite_sd}-FileStorage1",
        volume_retention => '60 days',
        label_fmt        => $offsite_pool,
        max_vol_bytes    => '536870912000',
    }

    # One schedule per day of the week.
    # Setting execution times so that it is unlikely jobs will run concurrently
    # with cron.{hourly,daily,monthly} or other cronscripts
    backup::schedule { $role::backup::config::days:
        pool    => $pool,
    }
    backup::weeklyschedule { $role::backup::config::days:
        pool    => $pool,
    }

    bacula::director::catalog { 'production':
        dbname     => 'bacula',
        dbuser     => 'bacula',
        dbhost     => $role::backup::config::database,
        dbport     => '3306',
        dbpassword => $passwords::bacula::database
    }

    # This has been taken straight from old files/backup/disklist-*
    bacula::director::fileset { 'root':
        includes     => [ '/' ]
    }
    bacula::director::fileset { 'a-sqldata':
        includes     => [ '/a/sqldata' ]
    }
    bacula::director::fileset { 'a-backup':
        includes => [ '/a/backup' ]
    }
    bacula::director::fileset { 'a-eventlogging':
        includes => [ '/a/eventlogging' ]
    }
    bacula::director::fileset { 'a-geowiki-data-private-bare':
        includes => [ $::geowiki::params::private_data_bare_path ]
    }
    bacula::director::fileset { 'home':
        includes => [ '/home' ]
    }
    bacula::director::fileset { 'mnt-a':
        includes => [ '/mnt/a' ]
    }
    bacula::director::fileset { 'roothome':
        includes => [ '/root' ]
    }
    bacula::director::fileset { 'srv-autoinstall':
        includes => [ '/srv/autoinstall' ]
    }
    bacula::director::fileset { 'srv-tftpboot':
        includes => [ '/srv/tftpboot' ]
    }
    bacula::director::fileset { 'srv-wikimedia':
        includes => [ '/srv/wikimedia' ]
    }
    bacula::director::fileset { 'srv-org-wikimedia':
        includes => [ '/srv/org/wikimedia' ]
    }
    bacula::director::fileset { 'var-lib-archiva':
        includes     => [ '/var/lib/archiva' ],
    }
    bacula::director::fileset { 'var-lib-jenkins-config':
        includes     => [ '/var/lib/jenkins/config.xml' ],
    }
    bacula::director::fileset { 'srv-gerrit-git':
        includes => [ '/srv/gerrit/git' ]
    }
    bacula::director::fileset { 'var-lib-jenkins-backups':
        includes => [ '/var/lib/jenkins/backups' ]
    }
    bacula::director::fileset { 'var-lib-mailman':
        includes => [ '/var/lib/mailman' ]
    }
    bacula::director::fileset { 'var-lib-puppet-ssl':
        includes => [ '/var/lib/puppet/ssl' ]
    }
    bacula::director::fileset { 'var-lib-puppet-volatile':
        includes => [ '/var/lib/puppet/volatile' ]
    }
    bacula::director::fileset { 'var-opendj-backups':
        includes => [ '/var/opendj/backups' ]
    }
    bacula::director::fileset { 'var-vmail':
        includes => [ '/var/vmail' ]
    }
    bacula::director::fileset { 'mysql-srv-backups':
        includes => [ '/srv/backups' ]
    }
    bacula::director::fileset { 'var-lib-carbon-whisper':
        includes => [ '/var/lib/carbon/whisper' ]
    }
    bacula::director::fileset { 'var-lib-ganglia':
        includes => [ '/var/lib/ganglia' ]
    }
    bacula::director::fileset { 'srv-ganglia':
        includes => [ '/srv/ganglia' ]
    }
    bacula::director::fileset { 'bugzilla-static':
        includes => [ '/srv/org/wikimedia/static-bugzilla' ]
    }
    bacula::director::fileset { 'bugzilla-backup':
        includes => [ '/srv/org/wikimedia/bugzilla-backup' ]
    }
    bacula::director::fileset { 'srv-deployment':
        includes => [ '/srv' ]
    }
    # As all /a this will hopefully no longer be needed at some point and will
    # be killed with fire
    bacula::director::fileset { 'mysql-a-backups':
        includes => [ '/a/backups' ]
    }
    bacula::director::fileset { 'mysql-bpipe-xfalse-pfalse-ifalse':
        includes => [],
        plugins  => [ 'mysql-bpipe-xfalse-pfalse-ifalse',]
    }
    bacula::director::fileset { 'mysql-bpipe-xfalse-pfalse-itrue':
        includes => [],
        plugins  => [ 'mysql-bpipe-xfalse-pfalse-itrue',]
    }
    bacula::director::fileset { 'mysql-bpipe-xfalse-ptrue-ifalse':
        includes => [],
        plugins  => [ 'mysql-bpipe-xfalse-ptrue-ifalse',]
    }
    bacula::director::fileset { 'mysql-bpipe-xfalse-ptrue-itrue':
        includes => [],
        plugins  => [ 'mysql-bpipe-xfalse-ptrue-itrue',]
    }
    bacula::director::fileset { 'mysql-bpipe-xtrue-pfalse-ifalse':
        includes => [],
        plugins  => [ 'mysql-bpipe-xtrue-pfalse-ifalse',]
    }
    bacula::director::fileset { 'mysql-bpipe-xtrue-pfalse-itrue':
        includes => [],
        plugins  => [ 'mysql-bpipe-xtrue-pfalse-itrue',]
    }
    bacula::director::fileset { 'mysql-bpipe-xtrue-ptrue-ifalse':
        includes => [],
        plugins  => [ 'mysql-bpipe-xtrue-ptrue-ifalse',]
    }
    bacula::director::fileset { 'mysql-bpipe-xtrue-ptrue-itrue':
        includes => [],
        plugins  => [ 'mysql-bpipe-xtrue-ptrue-itrue',]
    }
    bacula::director::fileset { 'bpipe-mysql-xfalse-ptrue-itrue':
        includes => [],
        plugins  => [ 'bpipe-mysql-xfalse-ptrue-itrue'],
    }
    bacula::director::fileset { 'var-lib-grafana':
        includes => [ '/var/lib/grafana' ],
    }
    bacula::director::fileset { 'srv-repos':
        includes => [ '/srv/repos' ],
    }
    bacula::director::fileset { 'yubiauth-aeads':
        includes => [ '/var/cache/yubikey-ksm/aeads' ],
    }
    bacula::director::fileset { 'openldap':
        includes => [ '/var/run/openldap-backup' ],
    }
    bacula::director::fileset { 'contint':
        includes => [ '/srv', '/var/lib/zuul', '/var/lib/jenkins' ],
        excludes => [ '/srv/jenkins/builds', '/var/lib/jenkins/builds', ],
    }
    bacula::director::fileset { 'etcd':
        includes => [ '/srv/backups/etcd' ]
    }
    bacula::director::fileset { 'otrsdb':
        includes => [ '/srv/backups/m2' ]
    }

    bacula::director::fileset { 'librenms':
        includes => [ '/var/lib/librenms' ]
    }

    bacula::director::fileset { 'torrus':
        includes => [ '/var/lib/torrus', '/var/cache/torrus' ]
    }

    bacula::director::fileset { 'smokeping':
        includes => [ '/var/lib/smokeping', '/var/cache/smokeping' ]
    }

    # The console should be on the director
    class { 'bacula::console':
        director   => $::fqdn,
    }

    nrpe::monitor_service { 'bacula_director':
        description  => 'bacula director process',
        nrpe_command => '/usr/lib/nagios/plugins/check_procs -w 1:1 -c 1:1 -u bacula -C bacula-dir',
    }

    ferm::service { 'bacula-director':
        proto  => 'tcp',
        port   => '9101',
        srange => '$PRODUCTION_NETWORKS',
    }

}
