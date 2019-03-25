# == Class: arclamp
#
# Aggregate captured stack traces from MediaWiki application servers,
# write them to disk, and generate SVG flame graphs.
#
# The aggregator reads captured traces from a Redis instance using pub/sub.
#
# MediaWiki servers capture these traces from PHP.
#
# For HHVM we use Xenon, the built-in sampling profiler for HHVM.
# <https://github.com/facebook/hhvm/wiki/Profiling#xenon>.
#
# For PHP 7 we use Excimer. <https://www.mediawiki.org/wiki/Excimer>
#
# === Parameters
#
# [*ensure*]
#   Description
#
# [*redis_host*]
#   Address of Redis server that is publishing stack traces.
#   Default: '127.0.0.1'.
#
# [*redis_port*]
#   Port of Redis server that is publishing stack traces.
#   Default: 6379.
#
# === Examples
#
#  class { 'arclamp':
#      ensure     => present,
#      redis_host => 'mwlog.example.net',
#      redis_port => 6379,
#  }
#
class arclamp(
    $ensure = present,
    $redis_host = '127.0.0.1',
    $redis_port = 6379,
) {
    require_package('python-redis')
    require_package('python-yaml')

    $config = {
        base_path => '/srv/xenon/logs',
        redis     => {
            host => $redis_host,
            port => $redis_port,
        },
        redis_channel => 'xenon',
        logs      => [
            # 336 hours is 14 days * 24 hours (T166624)
            { period => 'hourly',  format => '%Y-%m-%d_%H', retain => 336 },
            { period => 'daily',   format => '%Y-%m-%d',    retain => 90 },
        ],
    }

    group { 'xenon':
        ensure => $ensure,
    }

    user { 'xenon':
        ensure     => $ensure,
        gid        => 'xenon',
        shell      => '/bin/false',
        home       => '/nonexistent',
        system     => true,
        managehome => false,
    }

    file { '/srv/xenon':
        ensure => ensure_directory($ensure),
        links  => 'follow',
        owner  => 'xenon',
        group  => 'xenon',
        mode   => '0755',
        before => Service['xenon-log'],
    }

    file { '/etc/arclamp-log-xenon.yaml':
        ensure  => $ensure,
        content => ordered_yaml($config),
        owner   => 'root',
        group   => 'root',
        mode    => '0444',
        notify  => Service['xenon-log'],
    }

    file { '/usr/local/bin/xenon-log':
        ensure => $ensure,
        source => 'puppet:///modules/arclamp/arclamp-log',
        owner  => 'root',
        group  => 'root',
        mode   => '0555',
        notify => Service['xenon-log'],
    }

    systemd::service { 'xenon-log':
        ensure  => $ensure,
        content => systemd_template('xenon-log'),
    }

    # This is the Perl script that generates flame graphs.
    # It comes from <https://github.com/brendangregg/FlameGraph>.

    file { '/usr/local/bin/flamegraph.pl':
        ensure => $ensure,
        source => 'puppet:///modules/arclamp/flamegraph.pl',
        owner  => 'root',
        group  => 'root',
        mode   => '0555',
        notify => Service['xenon-log'],
    }


    # Walks /srv/xenon/logs looking for log files which do not have a
    # corresponding SVG file and calls flamegraph.pl on each of them.

    file { '/usr/local/bin/xenon-generate-svgs':
        ensure => $ensure,
        source => 'puppet:///modules/arclamp/xenon-generate-svgs',
        owner  => 'root',
        group  => 'root',
        mode   => '0555',
        before => Cron['xenon_generate_svgs'],
    }

    cron { 'xenon_generate_svgs':
        ensure  => $ensure,
        command => '/usr/local/bin/xenon-generate-svgs > /dev/null',
        user    => 'xenon',
        minute  => '*/15',
    }

    # xenon-grep is a simple CLI tool for parsing xenon logs
    # and printing a leaderboard of the functions which are most
    # frequently on-CPU.

    file { '/usr/local/bin/xenon-grep':
        ensure => $ensure,
        source => 'puppet:///modules/arclamp/xenon-grep',
        owner  => 'root',
        group  => 'root',
        mode   => '0555',
    }
}
