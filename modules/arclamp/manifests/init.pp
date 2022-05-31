# SPDX-License-Identifier: Apache-2.0
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
# [*compress_logs_days*]
#   How many days to wait before compressing logs.
#   Default: 3
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
    Wmflib::Ensure $ensure               = 'present',
    Stdlib::Host $redis_host             = '127.0.0.1',
    Stdlib::Port $redis_port             = 6379,
    String $errors_mailto                = 'performance-team-alert@wikimedia.org',
    Integer $compress_logs_days          = 3,
    Integer $retain_hourly_logs_hours    = 336, # 14 days
    Integer $retain_daily_logs_days      = 90,
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

    $timer_environment = {'MAILTO' => $errors_mailto}
    if $swift_account_name == undef {
        $swift_timer_environment = {}
    } else {
        $swift_timer_environment = {
            'ST_AUTH' => "${swift_auth_url}/auth/v1.0",
            'ST_USER' => $swift_user,
            'ST_KEY'  => $swift_key,
        }

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
    systemd::timer::job { 'arclamp_generate_svgs':
        ensure             => $ensure,
        description        => 'Regular jobs to generate svg files',
        user               => 'xenon',
        monitoring_enabled => false,
        logging_enabled    => false,
        send_mail          => true,
        environment        => $timer_environment + $swift_timer_environment,
        command            => '/srv/deployment/performance/arc-lamp/arclamp-generate-svgs',
        interval           => {'start' => 'OnCalendar', 'interval' => '*-*-* *:0/15:0'},
        require            => Package['performance/arc-lamp']
    }

    # Compress logs older than X days:
    systemd::timer::job { 'arclamp_compress_logs':
        ensure             => $ensure,
        description        => 'Regular jobs to compress arclamp logs',
        user               => 'xenon',
        monitoring_enabled => false,
        logging_enabled    => false,
        send_mail          => true,
        environment        => $timer_environment + $swift_timer_environment,
        command            => "/srv/deployment/performance/arc-lamp/arclamp-compress-logs ${compress_logs_days}",
        interval           => {'start' => 'OnCalendar', 'interval' => '*-*-* *:17:0'},
        require            => Package['performance/arc-lamp']
    }

    # Write Prometheus metrics to file under HTTP document root:
    systemd::timer::job { 'arclamp_generate_metrics':
        ensure             => $ensure,
        description        => 'Regular jobs to generate arclamp metrics',
        user               => 'xenon',
        monitoring_enabled => false,
        logging_enabled    => false,
        send_mail          => true,
        environment        => $timer_environment,
        command            => '/srv/deployment/performance/arc-lamp/arclamp-generate-metrics',
        interval           => {'start' => 'OnCalendar', 'interval' => '*-*-* *:0/2:0'},
        require            => Package['performance/arc-lamp']
    }

    # This supports running multiple pipelines; we profile CPU and
    # wall clock time separately.
    arclamp::profiler {
        default:
            ensure                   => present,
            redis_host               => $redis_host,
            redis_port               => $redis_port,
            retain_hourly_logs_hours => $retain_hourly_logs_hours,
            retain_daily_logs_days   => $retain_daily_logs_days;
        'excimer':
            description => 'PHP Excimer (CPU)';
        'excimer-wall':
            description => 'PHP Excimer (wall clock)';
        'excimer-k8s': # T288165
            description => 'PHP Excimer (k8s-experimental CPU)';
        'excimer-k8s-wall': # T288165
            description => 'PHP Excimer (k8s-experimental wall clock)';
    }
}
