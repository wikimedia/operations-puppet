# SPDX-License-Identifier: Apache-2.0
# @summary create systemtd timer to generate docker reports
# @param ensure ensurable parameter
# @param frequency either daily or weekly to indicate how often the timer should run
# @param proxy the http proxy to use, if any
# @param team the team to whom alerts should be routed
# @param min_debian_version the minimum Debian OS version supported for reports.
# @param target the system where to fetch a Docker image list from.
# @param registry_endpoint if target is 'registry', it indicates its endpoint.
# @param k8s_kubeconfig if target is 'kubernetes', it indicates the kubeconfig's path to use.
# @param rule_filename the filename of the rule config file to use.
define profile::docker::reporter::report(
    Wmflib::Ensure                 $ensure              = 'present',
    Enum['daily', 'weekly']        $frequency           = 'weekly',
    Optional[Stdlib::HTTPUrl]      $proxy               = undef,
    Optional[Wmflib::Team]         $team                = undef,
    Integer                        $min_debian_version  = 11,
    Enum['registry', 'kubernetes'] $target              = 'registry',
    Optional[String]               $registry_endpoint   = 'docker-registry.discovery.wmnet',
    Optional[String]               $k8s_kubeconfig_path = undef,
    String                         $rule_filename       = "${title}_${target}_rules.ini",
) {
    file { "/etc/docker-report/${rule_filename}":
        ensure => $ensure,
        owner  => 'root',
        group  => 'root',
        source => "puppet:///modules/profile/docker/reporter/${rule_filename}",
    }
    $hour = sprintf('%02d', fqdn_rand(24, $title))
    $environment = $proxy.then |$p| {{'http_proxy' => $p}}

    $interval = $frequency ? {
        'daily' => "*-*-* ${hour}:00:00",
        'weekly' => "Mon *-*-* ${hour}:00:00"
    }

    if $target == 'kubernetes' {
        $cluster_name = inline_template('<%= @title.gsub("_", "-") %>')
        $target_param = "--k8s-cluster ${cluster_name} --k8s-kubeconfig-path ${k8s_kubeconfig_path}"
    } else {
        $target_param = "--registry ${registry_endpoint}"
    }
    systemd::timer::job { "docker-reporter-${target}-${title}-images":
        ensure            => $ensure,
        description       => "Report on upgrades to ${title} images (${target}).",
        command           => "/usr/bin/docker-report --minimum-debian-version ${min_debian_version} --filter-file /etc/docker-report/${rule_filename} ${target_param}",
        interval          => {'start' => 'OnCalendar', 'interval' => $interval},
        user              => 'root',
        environment       => $environment,
        syslog_identifier => "docker-report-${target}-${title}",
        team              => $team,
    }
}
