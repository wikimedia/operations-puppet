# Create mydumper logical backups using the dump_shards.sh hosts
# of all production core (s*, x*) and misc (m*) hosts.
# Do that using a cron job on all backup hosts, all datacenters.
# If we are on the active datacenter, also send the backups to the
# long-term storage.
class role::mariadb::backup_mydumper {
    include ::profile::backup::host
    include ::passwords::mysql::dump

    group { 'dumps':
        ensure => present,
        system => true,
    }

    user { 'dumps':
        ensure     => present,
        gid        => 'dumps',
        shell      => '/bin/false',
        home       => '/srv/backups',
        system     => true,
        managehome => false,
    }

    file { '/srv/backups':
        ensure => directory,
        owner  => 'dumps',
        group  => 'dumps',
        mode   => '0600', # implicitly 0700 for dirs
    }

    file { '/usr/local/bin/dump_shards':
        ensure => present,
        owner  => 'dumps',
        group  => 'dumps',
        mode   => '0555',
        source => 'puppet:///modules/role/mariadb/dump_shards.sh',
    }

    file { '/etc/mysql/dump_shards.cnf':
        ensure  => present,
        owner   => 'dumps',
        group   => 'dumps',
        mode    => '0400',
        content => "[client]\nuser=${passwords::mysql::dump::user}\npassword=${passwords::mysql::dump::pass}\n",
    }

    cron { 'dumps-shards':
        minute  => 0,
        hour    => 22,
        weekday => 2,
        user    => 'dumps',
        command => '/usr/local/bin/dump_shards >/dev/null 2>&1',
        require => [File['/usr/local/bin/dump_shards.sh'],
                    File['/srv/backups'],
        ],
    }

    # produce logical backups on all backups hosts, but only send them
    # to the long term storage on one datacenter at a time
    $backups_active = hiera('role::mariadb::backups_mydumper::active', false)
    if $backups_active {
        backup::set { 'mysql-srv-backups': }
    }
}
