# == Class: testreduce
#
# Parsoid round-trip test result aggregator.
#
# === Parameters
#
# [*db_name*]
#   Database name for storing results.
#
# [*db_user*]
#   Database user.
#
# [*db_host*]
#   MySQL host. Default: 'localhost'.
#
# [*db_port*]
#   MySQL port. Default: 3306.
#
# [*coord_port*]
#   The result aggregator will listen on this port. Default: 8002.
#
# [*webapp_port*]
#   The user-facing webapp that displays test results will listen on
#   this port. Default: 8003.
#
class testreduce(
    $db_name,
    $db_user,
    $db_pass,
    $db_host     = 'localhost',
    $db_port     = 3306,
    $coord_port  = 8002,
    $webapp_port = 8003,
) {
    require_package('nodejs')
    require_package('npm')

    group { 'testreduce':
        ensure => present,
        system => true,
    }

    user { 'testreduce':
        gid        => 'testreduce',
        home       => '/srv/testreduce',
        managehome => false,
        system     => true,
    }

    file { '/etc/testreduce':
        ensure => directory,
        owner  => 'root',
        group  => 'root',
        mode   => '0755',
    }

    file { '/etc/testreduce/settings.js':
        content => template('testreduce/settings.js.erb'),
        owner   => 'root',
        group   => 'root',
        mode    => '0444',
        notify  => Service['testreduce'],
    }

    file { '/etc/init/testreduce.conf':
        source => 'puppet:///modules/testreduce/testreduce.upstart.conf',
        owner  => 'root',
        group  => 'root',
        mode   => '0444',
        notify => Service['testreduce'],
    }

    service { 'testreduce':
        ensure   => running,
        provider => upstart,
    }

    git::clone { 'mediawiki/services/parsoid/testreduce':
        ensure    => latest,
        owner     => 'root',
        group     => 'wikidev',
        directory => '/srv/testreduce',
    }
}
