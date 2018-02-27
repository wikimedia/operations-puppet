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

    $user = $passwords::mysql::dump::user
    $password = $passwords::mysql::dump::pass
    file { '/etc/mysql/backup.cnf':
        ensure  => present,
        owner   => 'dump',
        group   => 'dump',
        mode    => '0400',
        content => template("profile/mariadb/backup-${::site}.cnf.erb")
    }

    file { '/usr/local/bin/dump_sections.py':
        ensure  => present,
        owner   => 'root',
        group   => 'root',
        mode    => '0755',
        source  => 'puppet:///modules/profile/mariadb/dump_sections.py'
        require => File['/etc/mysql/backup.cnf'],
    }

    cron { 'dumps-sections':
        minute  => 0,
        hour    => 19,
        weekday => 2,
        user    => 'dump',
        command => '/usr/bin/python3 /usr/local/bin/dump_sections.py >/dev/null 2>&1',
        require => [File['/usr/local/bin/dump_sections.py'],
                    File['/srv/backups'],
        ],
    }
}
