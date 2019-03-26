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

    # Global setup
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
    }

    file { '/usr/local/bin/arclamp-log':
        ensure => $ensure,
        source => 'puppet:///modules/arclamp/arclamp-log',
        owner  => 'root',
        group  => 'root',
        mode   => '0555',
    }
    # This is the Perl script that generates flame graphs.
    # It comes from <https://github.com/brendangregg/FlameGraph>.

    file { '/usr/local/bin/flamegraph.pl':
        ensure => $ensure,
        source => 'puppet:///modules/arclamp/flamegraph.pl',
        owner  => 'root',
        group  => 'root',
        mode   => '0555',
    }
    # Walks /srv/xenon/logs looking for log files which do not have a
    # corresponding SVG file and calls flamegraph.pl on each of them.

    file { '/usr/local/bin/arclamp-generate-svgs':
        ensure => $ensure,
        source => 'puppet:///modules/arclamp/arclamp-generate-svgs',
        owner  => 'root',
        group  => 'root',
        mode   => '0555',
    }

    cron { 'arclamp_generate_svgs':
        ensure  => $ensure,
        command => '/usr/local/bin/arclamp-generate-svgs > /dev/null',
        user    => 'xenon',
        minute  => '*/15',
        require => File['/usr/local/bin/arclamp-generate-svgs']
    }

    file { '/usr/local/bin/arclamp-grep':
        ensure => $ensure,
        source => 'puppet:///modules/arclamp/arclamp-grep',
        owner  => 'root',
        group  => 'root',
        mode   => '0555',
    }


    arclamp::instance {
        default:
            ensure     => present,
            redis_host => $redis_host,
            redis_port => $redis_port;
        'xenon':
            description => 'HHVM Xenon',
            label       => '';
        'excimer':
            description => 'PHP Excimer';
    }
}
