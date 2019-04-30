# Create mydumper logical backups using the dump_shards.sh hosts
# of all production core (s*, x*) and misc (m*) hosts.
# Do that using a cron job on all backup hosts, all datacenters.
# Note this profile creates the backups, but does not send them
# to bacula or other long-term storage, that is handled by the
# mariadb::backup::bacula class.
class profile::mariadb::backup::mydumper {
    include ::passwords::mysql::dump

    require_package(
        'mydumper',
        'python3',
        'python3-yaml',
        'python3-pymysql',
    )

    group { 'dump':
        ensure => present,
        system => true,
    }

    user { 'dump':
        ensure     => present,
        gid        => 'dump',
        shell      => '/bin/false',
        home       => '/srv/backups',
        system     => true,
        managehome => false,
    }

    file { '/srv/backups':
        ensure => directory,
        owner  => 'dump',
        group  => 'dump',
        mode   => '0600', # implicitly 0700 for dirs
    }

    file { '/srv/backups/dumps':
        ensure  => directory,
        owner   => 'dump',
        group   => 'dump',
        mode    => '0600', # implicitly 0700 for dirs
        require => File['/srv/backups'],
    }

    file { ['/srv/backups/dumps/ongoing',
            '/srv/backups/dumps/latest',
            '/srv/backups/dumps/archive',
        ]:
        ensure  => directory,
        owner   => 'dump',
        group   => 'dump',
        mode    => '0600', # implicitly 0700 for dirs
        require => File['/srv/backups/dumps'],
    }

    $user = $passwords::mysql::dump::user
    $password = $passwords::mysql::dump::pass
    $stats_user = $passwords::mysql::dump::stats_user
    $stats_password = $passwords::mysql::dump::stats_pass
    file { '/etc/mysql/backups.cnf':
        ensure    => present,
        owner     => 'dump',
        group     => 'dump',
        mode      => '0400',
        show_diff => false,
        content   => template("profile/mariadb/backups-${::hostname}.cnf.erb"),
    }
    # Logging support
    file { '/var/log/mariadb-backups':
        ensure => directory,
        owner  => 'dump',
        group  => 'dump',
        mode   => '0740',
    }

    file { '/usr/local/bin/backup_mariadb.py':
        ensure  => present,
        owner   => 'root',
        group   => 'root',
        mode    => '0755',
        source  => 'puppet:///modules/profile/mariadb/backup_mariadb.py',
        require => File['/var/log/mariadb-backups'],
    }
    file { '/usr/local/bin/recover_dump.py':
        ensure  => present,
        owner   => 'root',
        group   => 'root',
        mode    => '0755',
        source  => 'puppet:///modules/profile/mariadb/recover_dump.py',
        require => File['/srv/backups/dumps/latest'],
    }

    cron { 'dumps-sections':
        minute  => 0,
        hour    => 17,
        weekday => 2,
        user    => 'dump',
        command => '/usr/bin/python3 /usr/local/bin/backup_mariadb.py --config-file=/etc/mysql/backups.cnf >/dev/null 2>&1',
        require => [File['/usr/local/bin/backup_mariadb.py'],
                    File['/etc/mysql/backups.cnf'],
                    File['/srv/backups/dumps/ongoing'],
        ],
    }
}
