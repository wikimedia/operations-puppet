# == Class: arclamp
#
# Aggregate captured stack traces from MediaWiki application servers,
# write them to disk, and generate SVG flame graphs.
#
# The aggregator reads captured traces from a Redis instance using pub/sub.
#
# MediaWiki servers capture these traces from PHP.
#
# For PHP 7 we use Excimer: <https://www.mediawiki.org/wiki/Excimer>
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

    file { '/srv/arclamp':
        ensure => ensure_link($ensure),
        target => '/srv/xenon',
    }

    scap::target { 'performance/arc-lamp':
        service_name => 'arclamp',
        deploy_user  => 'deploy-service',
    }

    file { '/usr/local/bin/arclamp-grep':
        ensure => ensure_link($ensure),
        target => '/srv/deployment/performance/arc-lamp/arclamp-grep.py',
    }

    # Generate flamegraphs from raw log data:
    cron { 'arclamp_generate_svgs':
        ensure      => $ensure,
        command     => '/srv/deployment/performance/arc-lamp/arclamp-generate-svgs >/dev/null',
        user        => 'xenon',
        minute      => '*/15',
        environment => 'MAILTO=performance-team@wikimedia.org',
        require     => Package['performance/arc-lamp']
    }

    # Compress logs older than 7 days:
    cron { 'arclamp_compress_logs':
        ensure      => $ensure,
        command     => '/srv/deployment/performance/arc-lamp/arclamp-compress-logs 7 >/dev/null',
        user        => 'xenon',
        minute      => '17', # intentionally offset from other jobs
        environment => 'MAILTO=performance-team@wikimedia.org',
        require     => Package['performance/arc-lamp']
    }

    # Write Prometheus metrics to file under HTTP document root:
    cron { 'arclamp_generate_metrics':
        ensure      => $ensure,
        command     => '/srv/deployment/performance/arc-lamp/arclamp-generate-metrics >/dev/null',
        user        => 'xenon',
        minute      => '*/2',
        environment => 'MAILTO=performance-team@wikimedia.org',
        require     => Package['performance/arc-lamp']
    }

    # This supports running multiple pipelines; in the past we had one
    # for HHVM and one for PHP7.  Currently only the latter is needed.
    arclamp::profiler {
        default:
            ensure     => present,
            redis_host => $redis_host,
            redis_port => $redis_port;
        'excimer':
            description => 'PHP Excimer';
    }
}
