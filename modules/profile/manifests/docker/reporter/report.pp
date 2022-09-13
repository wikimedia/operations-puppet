# SPDX-License-Identifier: Apache-2.0
# @summary create systemtd timer to generate docker reports
# @param ensure ensurable parameter
# @param frequency either daily or weekly to indicate how often the timer should run
# @param proxy the http proxy to use, if any
define profile::docker::reporter::report(
    Wmflib::Ensure            $ensure    = 'present',
    Enum['daily', 'weekly']   $frequency = 'weekly',
    Optional[Stdlib::HTTPUrl] $proxy     = undef,
) {
    file { "/etc/docker-report/${title}_rules.ini":
        ensure => $ensure,
        owner  => 'root',
        group  => 'root',
        source => "puppet:///modules/profile/docker/reporter/${title}_rules.ini",
    }
    $hour = sprintf('%02d', fqdn_rand(24, $title))
    $environment = $proxy.then |$p| {{'http_proxy' => $p}}

    $interval = $frequency ? {
        'daily' => "*-*-* ${hour}:00:00",
        'weekly' => "Mon *-*-* ${hour}:00:00"
    }
    systemd::timer::job { "docker-reporter-${title}-images":
        ensure            => $ensure,
        description       => "Report on upgrades to ${title} images.",
        command           => "/usr/bin/docker-report --filter-file /etc/docker-report/${title}_rules.ini docker-registry.wikimedia.org",
        interval          => {'start' => 'OnCalendar', 'interval' => $interval},
        user              => 'root',
        environment       => $environment,
        syslog_identifier => "docker-report-${title}",
    }
}
