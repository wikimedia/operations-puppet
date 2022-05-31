# SPDX-License-Identifier: Apache-2.0
define arclamp::profiler(
    String $description,
    Stdlib::Host $redis_host,
    Stdlib::Port::Unprivileged $redis_port,
    String $label = ".${title}",
    Wmflib::Ensure $ensure = 'present',
    Integer $retain_hourly_logs_hours = 336, # 14 days
    Integer $retain_daily_logs_days = 90,
) {
    # Verify the title will not create us any issues
    assert_type(Pattern[/[a-z]+/], $title)

    $config = {
        base_path => '/srv/xenon/logs',
        redis     => {
            host => $redis_host,
            port => $redis_port,
        },
        redis_channel => $title,
        logs          => [
          { period => 'hourly',
            format => "%Y-%m-%d_%H${label}",
            retain => $retain_hourly_logs_hours,
          }, {
            period => 'daily',
            format => "%Y-%m-%d${label}",
            retain => $retain_daily_logs_days,
          },
        ],
    }

    file { "/etc/arclamp-log-${title}.yaml":
        ensure  => $ensure,
        content => to_yaml($config),
        owner   => 'root',
        group   => 'root',
        mode    => '0444',
        notify  => Service["${title}-log"],
    }

    systemd::service { "${title}-log":
        ensure    => $ensure,
        content   => systemd_template('arclamp-log'),
        subscribe => Package['performance/arc-lamp'],
        require   => File['/srv/xenon']
    }
}
