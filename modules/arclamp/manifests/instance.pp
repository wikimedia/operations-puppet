define arclamp::instance(
    String $description,
    Stdlib::Host $redis_host,
    Stdlib::Port::Unprivileged $redis_port,
    String $label = ".${title}",
    Wmflib::Ensure $ensure = 'present',
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
    logs      => [
        # 336 hours is 14 days * 24 hours (T166624)
        { period => 'hourly',  format => "%Y-%m-%d_%H${label}", retain => 336 },
        { period => 'daily',   format => "%Y-%m-%d${label}",    retain => 90 },
    ],
    }

    file { "/etc/arclamp-log-${title}.yaml":
        ensure  => $ensure,
        content => ordered_yaml($config),
        owner   => 'root',
        group   => 'root',
        mode    => '0444',
        notify  => Service["${title}-log"],
    }

    systemd::service { "${title}-log":
        ensure    => $ensure,
        content   => systemd_template('arclamp-log'),
        subscribe => File['/usr/local/bin/arclamp-log'],
        require   => File['/srv/xenon']
    }
}
