# SPDX-License-Identifier: Apache-2.0
# Create mydumper logical backups using the dump_shards.sh hosts
# of all production core (s*, x*) and misc (m*) hosts.
# Do that using a cron job on all backup hosts, all datacenters.
# Note this profile creates the backups, but does not send them
# to bacula or other long-term storage, that is handled by the
# dbbackups::bacula class.
class profile::dbbackups::mydumper {
    include ::passwords::mysql::dump

    ensure_packages([
        'wmfbackups',  # we now install all software from debian package
        'mydumper',  # mydumper is only a soft dependency, explicitly install it
    ])

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
        mode   => '0711', # o+x so we can mount and check /ongoing
    }

    file { '/srv/backups/dumps':
        ensure  => directory,
        owner   => 'dump',
        group   => 'dump',
        mode    => '0711', # o+x so we can mount and check /ongoing
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
    file { '/etc/wmfbackups/backups.cnf':
        ensure    => present,
        owner     => 'dump',
        group     => 'dump',
        mode      => '0400',
        show_diff => false,
        content   => template("profile/dbbackups/${::hostname}.cnf.erb"),
    }
    # separate file for common statistics db config
    file { '/etc/wmfbackups/statistics.cnf':
        ensure    => present,
        owner     => 'dump',
        group     => 'dump',
        mode      => '0400',
        show_diff => false,
        content   => template('profile/dbbackups/statistics.cnf.erb'),
    }
    # Logging support
    file { '/var/log/mariadb-backups':
        ensure => directory,
        owner  => 'dump',
        group  => 'dump',
        mode   => '0740',
    }

    cron { 'dumps-sections':
        minute  => 0,
        hour    => 0,
        weekday => 2,
        user    => 'dump',
        command => 'backup-mariadb --config-file=/etc/wmfbackups/backups.cnf >/dev/null 2>&1',
        require => [Package['wmfbackups'],
                    File['/etc/wmfbackups/backups.cnf'],
                    File['/srv/backups/dumps/ongoing'],
        ],
    }

    class { 'toil::systemd_scope_cleanup': }  # T265323
}
