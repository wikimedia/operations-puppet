# == Class: xenon
#
# Xenon is an HHVM extension that periodically captures a stack trace of
# PHP code. MediaWiki servers send the captured trace via Redis pub/sub.
# This class implements an aggregator that stores captured traces to disk
# and generates SVG flame graphs from them.
#
# === Parameters
#
# [*ensure*]
#   Description
#
# [*redis_host*]
#   Address of Redis server that is publishing Xenon traces.
#   Default: '127.0.0.1'.
#
# [*redis_port*]
#   Port of Redis server that is publishing Xenon traces.
#   Default: 6379.
#
# === Examples
#
#  class { 'xenon':
#      ensure     => present,
#      redis_host => 'mwlog.example.net',
#      redis_port => 6379,
#  }
#
class xenon(
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
        logs      => [
            { period => 'hourly',  format => '%Y-%m-%d_%H', retain => 24 },
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

    file { '/etc/xenon-log.yaml':
        ensure  => $ensure,
        content => ordered_yaml($config),
        owner   => 'root',
        group   => 'root',
        mode    => '0444',
        notify  => Service['xenon-log'],
    }

    file { '/usr/local/bin/xenon-log':
        ensure => $ensure,
        source => 'puppet:///modules/xenon/xenon-log',
        owner  => 'root',
        group  => 'root',
        mode   => '0555',
        notify => Service['xenon-log'],
    }

    base::service_unit { 'xenon-log':
        ensure  => $ensure,
        systemd => true,
        upstart => true,
    }

    # This is the Perl script that generates flame graphs.
    # It comes from <https://github.com/brendangregg/FlameGraph>.

    file { '/usr/local/bin/flamegraph.pl':
        ensure => $ensure,
        source => 'puppet:///modules/xenon/flamegraph.pl',
        owner  => 'root',
        group  => 'root',
        mode   => '0555',
        notify => Service['xenon-log'],
    }


    # Walks /srv/xenon/logs looking for log files which do not have a
    # corresponding SVG file and calls flamegraph.pl on each of them.

    file { '/usr/local/bin/xenon-generate-svgs':
        ensure => $ensure,
        source => 'puppet:///modules/xenon/xenon-generate-svgs',
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
        source => 'puppet:///modules/xenon/xenon-grep',
        owner  => 'root',
        group  => 'root',
        mode   => '0555',
    }
}
