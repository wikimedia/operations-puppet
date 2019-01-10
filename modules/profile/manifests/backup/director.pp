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
    $dbhost = hiera('profile::backup::director::database'),
    $dbpass = hiera('profile::backup::director::dbpass'),
){
    include ::profile::base::firewall

    class { 'bacula::director':
        sqlvariant          => 'mysql',
        max_dir_concur_jobs => '10',
    }

    # One pool for all
    bacula::director::pool { $pool:
        max_vols         => 60,
        storage          => "${onsite_sd}-FileStorage1",
        volume_retention => '30 days',
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
        max_vols         => 60,
        storage          => "${offsite_sd}-FileStorage1",
        volume_retention => '30 days',
        label_fmt        => $offsite_pool,
        max_vol_bytes    => '536870912000',
    }

    # One schedule per day of the week.
    # Setting execution times so that it is unlikely jobs will run concurrently
    # with cron.{hourly,daily,monthly} or other cronscripts
    backup::schedule { $days:
        pool => $pool,
    }
    backup::weeklyschedule { $days:
        pool => $pool,
    }
    backup::hourlyschedule { $days:
        pool    => $pool,
    }

    bacula::director::catalog { 'production':
        dbname     => 'bacula',
        dbuser     => 'bacula',
        dbhost     => $dbhost,
        dbport     => '3306',
        dbpassword => $dbpass,
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
    # TODO: remove this when geowiki site is no longer needed.
    # https://phabricator.wikimedia.org/T190059
    bacula::director::fileset { 'a-geowiki-data-private-bare':
        includes => [ '/srv/geowiki/data-private-bare' ]
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
    bacula::director::fileset { 'srv-docroot-org-wikimedia-doc':
        includes => [ '/srv/docroot/org/wikimedia/doc' ]
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
    bacula::director::fileset { 'var-lib-carbon-whisper-coal':
        includes => [ '/var/lib/carbon/whisper/coal' ]
    }
    bacula::director::fileset { 'var-lib-graphite-web-graphite-db':
        includes => [ '/var/lib/graphite-web/graphite.db' ]
    }
    bacula::director::fileset { 'var-lib-jenkins-backups':
        includes => [ '/var/lib/jenkins/backups' ]
    }
    bacula::director::fileset { 'var-lib-mailman':
        includes => [ '/var/lib/mailman' ]
    }
    bacula::director::fileset { 'var-lib-puppet-ssl':
        includes => [ '/var/lib/puppet/ssl', '/var/lib/puppet/server/ssl' ]
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
    bacula::director::fileset { 'mysql-srv-backups-latest':
        includes => [ '/srv/backups/latest' ]
    }
    bacula::director::fileset { 'bugzilla-static':
        includes => [ '/srv/org/wikimedia/static-bugzilla' ]
    }
    bacula::director::fileset { 'bugzilla-backup':
        includes => [ '/srv/org/wikimedia/bugzilla-backup' ]
    }
    bacula::director::fileset { 'rt-static':
        includes => [ '/srv/org/wikimedia/static-rt' ]
    }
    bacula::director::fileset { 'srv-deployment':
        includes => [ '/srv' ]
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

    bacula::director::fileset { 'librenms':
        includes => [ '/var/lib/librenms', '/srv/librenms' ]
    }

    bacula::director::fileset { 'smokeping':
        includes => [ '/var/lib/smokeping', '/var/cache/smokeping' ]
    }

    bacula::director::fileset { 'rancid':
        includes => [ '/var/lib/rancid' ]
    }

    bacula::director::fileset { 'hadoop-namenode-backup':
        includes => [ '/srv/backup/hadoop/namenode' ]
    }

    bacula::director::fileset { 'postgresql':
        includes => [ '/srv/postgres-backup/' ]
    }

    bacula::director::fileset { 'netbox':
        includes => [ '/srv/deployment/netbox/deploy/netbox/netbox/media/',
                      '/srv/deployment/netbox/deploy/netbox/netbox/reports/',
                      '/srv/postgres-backup/'
                    ]
    }

    bacula::director::fileset { 'tor':
        includes => [ '/var/lib/tor/', '/var/lib/tor-instances/' ]
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
