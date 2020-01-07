define profile::docker::reporter::report(
    Enum['daily', 'weekly'] $frequency,
    String $proxy
) {
    file { "/etc/docker-report/${title}_rules.ini":
        ensure => present,
        owner  => 'root',
        group  => 'root',
        source => "puppet:///modules/profile/docker/reporter/${title}_rules.ini",
    }
    $hour = sprintf('%02d', fqdn_rand(24, $title))
    $interval = $frequency ? {
        'daily' => "*-*-* ${hour}:00:00",
        'weekly' => "Mon *-*-* ${hour}:00:00"
    }
    systemd::timer::job { "docker-reporter-${title}-images":
        description        => "Report on upgrades to ${title} images.",
        command            => "/usr/bin/docker-report --filter-file /etc/docker-report/${title}_rules.ini docker-registry.wikimedia.org",
        interval           => {'start' => 'OnCalendar', 'interval' => $interval},
        user               => 'root',
        environment        => {'http_proxy' => $proxy},
        # TODO: enable monitoring
        monitoring_enabled => false,

    }
}
