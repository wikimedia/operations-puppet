# A set of roles for the backup director, storage and client as they are
# configured in WMF

class role::backup::config {
    $director = 'helium.eqiad.wmnet'
    $database = 'db1001.eqiad.wmnet'
}

class role::backup::director {
    include role::backup::config
    include passwords::bacula

    system_role { 'role::backup::director': description => 'Backup server' }

    class { 'bacula::director':
        sqlvariant          => 'mysql',
        max_dir_concur_jobs => '10',
    }

    # One pool for all
    bacula::director::pool { 'production':
        max_vols         => 30,
        storage          => 'FileStorage1',
        volume_retention => '180 days',
    }

    # One schedule per day of the week.
    # Setting execution times so that it is unlikely jobs will run concurrently
    # with cron.{hourly,daily,monthly} or other cronscripts
    $days = ['Sat', 'Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri']

    backup::schedule { $days:
        pool    => 'production',
    }

    bacula::director::catalog { 'production':
        dbname      => 'bacula',
        dbuser      => 'bacula',
        dbhost      => $role::backup::config::database,
        dbport      => '3306',
        dbpassword  => $passwords::bacula::database
    }

    # This has been taken straight from old files/backup/disklist-*
    bacula::director::fileset { 'a-sqldata':
        includes     => [ '/a/sqldata']
    }
    bacula::director::fileset { 'a-backup':
        includes => [ '/a/backup' ]
    }
    bacula::director::fileset { 'a-eventlogging':
        includes => [ '/a/eventlogging' ]
    }
    bacula::director::fileset { 'home':
        includes => [ '/home' ]
    }
    bacula::director::fileset { 'mnt-a':
        includes => [ '/mnt/a' ]
    }
    bacula::director::fileset { 'root':
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
    bacula::director::fileset { 'svnroot':
        includes => [ '/svnroot' ]
    }
    bacula::director::fileset { 'svnroot-bak':
        includes => [ '/svnroot/bak' ]
    }
    bacula::director::fileset { 'var-lib-gerrit2-review_site-git':
        includes => [ '/var/lib/gerrit2/review_site/git' ]
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
    bacula::director::fileset { 'var-opendj-backups':
        includes => [ '/var/opendj/backups' ]
    }
    bacula::director::fileset { 'var-vmail':
        includes => [ '/var/vmail' ]
    }

    # The console should be on the director
    class { 'bacula::console':
        director   => $::fqdn,
    }
}

class role::backup::storage() {
    include role::backup::config

    system_role { 'role::backup::storage': description => 'Backup Storage' }

    include nfs::netapp::common

    class { 'bacula::storage':
        director            => $role::backup::config::director,
        sd_max_concur_jobs  => 5,
        sqlvariant          => 'mysql',
    }

    # We have two storage devices to overcome any limitations from backend
    # infrastructure (e.g. Netapp used to have only < 16T volumes)
    file { ['/srv/bacula-sd1',
            '/srv/bacula-sd2' ]:
        ensure  => directory,
        owner   => 'bacula',
        group   => 'bacula',
        mode    => '0660',
        require => Class['bacula::storage'],
    }

    mount { '/srv/bacula-sd1' :
        ensure  => mounted,
        device  => "${nfs::netapp::common::device}:/vol/bacula-sd1",
        fstype  => 'nfs',
        options => "${nfs::netapp::common::options},rw",
        require => File['/srv/bacula-sd1'],
    }

    mount { '/srv/bacula-sd2' :
        ensure  => mounted,
        device  => "${nfs::netapp::common::device}:/vol/bacula-sd2",
        fstype  => 'nfs',
        options => "${nfs::netapp::common::options},rw",
        require => File['/srv/bacula-sd2'],
    }

    bacula::storage::device { 'FileStorage1':
        device_type     => 'File',
        media_type      => 'File',
        archive_device  => '/srv/bacula-sd1',
        max_concur_jobs => 2,
    }

    bacula::storage::device { 'FileStorage2':
        device_type     => 'File',
        media_type      => 'File',
        archive_device  => '/srv/bacula-sd2',
        max_concur_jobs => 2,
    }
}
