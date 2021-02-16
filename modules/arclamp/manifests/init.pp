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
    Wmflib::Ensure $ensure   = 'present',
    Stdlib::Host $redis_host = '127.0.0.1',
    Stdlib::Port $redis_port = 6379,
    String $errors_mailto    = 'performance-team@wikimedia.org',
    Optional[String] $swift_account_name = undef,
    Optional[String] $swift_auth_url     = undef,
    Optional[String] $swift_user         = undef,
    Optional[String] $swift_key          = undef,
){

    ensure_packages(['python3-redis', 'python3-yaml', 'python3-swiftclient'])

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
        ensure => stdlib::ensure($ensure, 'directory'),
        links  => 'follow',
        owner  => 'xenon',
        group  => 'xenon',
        mode   => '0755',
    }

    file { '/srv/arclamp':
        ensure => stdlib::ensure($ensure, 'link'),
        target => '/srv/xenon',
    }

    scap::target { 'performance/arc-lamp':
        service_name => 'arclamp',
        deploy_user  => 'deploy-service',
    }

    file { '/usr/local/bin/arclamp-grep':
        ensure => stdlib::ensure($ensure, 'link'),
        target => '/srv/deployment/performance/arc-lamp/arclamp-grep.py',
    }

    $cron_environment = ["MAILTO=${errors_mailto}"]
    if $swift_account_name == undef {
        $swift_cron_environment = []
    } else {
        $swift_cron_environment = [
            "ST_AUTH=${swift_auth_url}/auth/v1.0",
            "ST_USER=${swift_user}",
            "ST_KEY=${swift_key}",
        ]

        # Also write credentials where they can be sourced by root
        # users who need to manually run the swift CLI tool for setup
        # or debugging:
        $account_file = "/etc/swift/account_${swift_account_name}.env"
        file { '/etc/swift':
            ensure => stdlib::ensure($ensure, 'directory'),
            owner  => 'root',
            group  => 'root',
            mode   => '0750',
        }
        file { $account_file:
            ensure  => $ensure,
            owner   => 'root',
            group   => 'root',
            mode    => '0440',
            content => "export ST_AUTH=${swift_auth_url}/auth/v1.0\nexport ST_USER=${swift_user}\nexport ST_KEY=${swift_key}\n"
        }
    }

    # Generate flamegraphs from raw log data:
    cron { 'arclamp_generate_svgs':
        ensure      => $ensure,
        command     => '/srv/deployment/performance/arc-lamp/arclamp-generate-svgs >/dev/null',
        user        => 'xenon',
        minute      => '*/15',
        environment => $cron_environment + $swift_cron_environment,
        require     => Package['performance/arc-lamp']
    }

    # Compress logs older than 7 days:
    cron { 'arclamp_compress_logs':
        ensure      => $ensure,
        command     => '/srv/deployment/performance/arc-lamp/arclamp-compress-logs 7 >/dev/null',
        user        => 'xenon',
        minute      => '17', # intentionally offset from other jobs
        environment => $cron_environment + $swift_cron_environment,
        require     => Package['performance/arc-lamp']
    }

    # Write Prometheus metrics to file under HTTP document root:
    cron { 'arclamp_generate_metrics':
        ensure      => $ensure,
        command     => '/srv/deployment/performance/arc-lamp/arclamp-generate-metrics >/dev/null',
        user        => 'xenon',
        minute      => '*/2',
        environment => $cron_environment,
        require     => Package['performance/arc-lamp']
    }

    # This supports running multiple pipelines; we profile CPU and
    # wall clock time separately.
    arclamp::profiler {
        default:
            ensure     => present,
            redis_host => $redis_host,
            redis_port => $redis_port;
        'excimer':
            description => 'PHP Excimer (CPU)';
        'excimer-wall':
            description => 'PHP Excimer (wall clock)';
    }
}
