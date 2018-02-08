# Create mydumper logical backups using the dump_shards.sh hosts
# of all production core (s*, x*) and misc (m*) hosts.
# Do that using a cron job on all backup hosts, all datacenters.
# Note this profile creates the backups, but does not send them
# to bacula or other long-term storage, that is handled by the
# mariadb::backup::bacula class.
class profile::mariadb::backup::mydumper {
    include ::passwords::mysql::dump

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

    file { '/usr/local/bin/dump_shards':
        ensure => present,
        owner  => 'dump',
        group  => 'dump',
        mode   => '0555',
        source => 'puppet:///modules/role/mariadb/dump_shards.sh',
    }

    file { '/etc/mysql/dump_shards.cnf':
        ensure  => present,
        owner   => 'dump',
        group   => 'dump',
        mode    => '0400',
        content => "[client]\nuser=${passwords::mysql::dump::user}\npassword=${passwords::mysql::dump::pass}\n",
    }

    cron { 'dumps-shards':
        minute  => 0,
        hour    => 22,
        weekday => 2,
        user    => 'dump',
        command => '/usr/local/bin/dump_shards >/dev/null 2>&1',
        require => [File['/usr/local/bin/dump_shards'],
                    File['/srv/backups'],
        ],
    }
}
