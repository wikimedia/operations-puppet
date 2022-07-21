# SPDX-License-Identifier: Apache-2.0
# @summary resource to configure icmp checks for a specific service
# @param instance_label name the host part of 'instance' label to use
# @param ip4 The IP address to connect to
# @param ip6 The IP6 address to connect to
# @param ip_families indicate support for ipv4 and/or ipv6
# @param team the WMF team to alert
# @param severity The severity of the alert
# @param timeout the probe timeout
# @param prometheus_instance prometheus instance to deploy to, defaults to 'ops'
define prometheus::blackbox::check::icmp (
    Stdlib::Fqdn                         $instance_label      = $facts['networking']['hostname'],
    Stdlib::IP::Address::V4::Nosubnet    $ip4                 = $facts['networking']['ip'],
    Stdlib::IP::Address::V6::Nosubnet    $ip6                 = $facts['networking']['ip6'],
    Array[Enum['ip4', 'ip6']]            $ip_families         = ['ip4', 'ip6'],
    String[1]                            $team                = 'sre',
    Prometheus::Alert::Severity          $severity            = 'critical',
    Pattern[/\d+[ms]/]                   $timeout             = '3s',
    Wmflib::Sites                        $site                = $::site,  # lint:ignore:top_scope_facts
    String[1]                            $prometheus_instance = 'ops',
) {
    $safe_title = $title.regsubst('\W', '_', 'G')
    $module_title = $safe_title
    $alert_title = "alerts_${safe_title}.yml"
    $target_file = "/srv/prometheus/${prometheus_instance}/targets/probes-custom_puppet-icmp.yaml"

    $icmp_module_params = {
        'ip_protocol_fallback' => false,
    }
    $module_config = {
        'modules' => Hash($ip_families.map |$family| {
            [ "icmp_${safe_title}_${family}",
              {
                  'prober' => 'icmp',
                  'timeout' => $timeout,
                  'icmp' => $icmp_module_params + { 'preferred_ip_protocol' => $family }
              }
            ]
        }),
    }
    $target_config = $ip_families.map |$family| {
        $address = ($family == 'ip4').bool2str($ip4, $ip6)
        $data = {
            'labels' => {
                'address' => $address,
                'family'  => $family,
                'module'  => "icmp_${safe_title}_${family}",
            },
            'targets' => ["${instance_label}:0@${address}"],
        }
        $data
    }

    $page_text = $severity ? {
        'page'   => ' #page',
        default => '',
    }

    $alert_config = {
        'groups' => [
          {
            'name'  => 'puppet_probes',
            'rules' => [{
                'alert'      => 'ProbeDown',
                'expr'       => "avg_over_time(probe_success{module=~'icmp_${safe_title}_.*'}[1m]) * 100 < 75",
                'for'         => '2m',
                'labels'      => {
                    'team'     => $team,
                    'severity' => $severity,
                },
                'annotations' => {
                    'description' => '{{ $labels.instance }} failed when probed by {{ $labels.module }} from {{ $externalLabels.site }}. Availability is {{ $value }}%.',
                    'summary'     => "Service {{ \$labels.instance }} has failed probes ({{ \$labels.module }})${page_text}",
                    'dashboard'   => 'https://grafana.wikimedia.org/d/O0nHhdhnz/network-probes-overview?var-job={{ $labels.job }}&var-module=All',
                    'logs'        => 'https://logstash.wikimedia.org/app/dashboards#/view/f3e709c0-a5f8-11ec-bf8e-43f1807d5bc2?_g=(filters:!((query:(match_phrase:(service.name:{{ $labels.module }})))))',
                    'runbook'     => 'https://wikitech.wikimedia.org/wiki/Network_monitoring#ProbeDown',
                },
            }],
          },
        ].filter |$alert| { $alert != undef },
    }
    $module_params = {
        'content' => $module_config.wmflib::to_yaml,
        'tag'     => "prometheus::blackbox::check::icmp::${::site}::${prometheus_instance}::module",
    }
    $alert_rule_params  = {
        'instance' => $prometheus_instance,
        'content' => $alert_config.wmflib::to_yaml,
        'tag'     => "prometheus::blackbox::check::icmp::${::site}::${prometheus_instance}::alert",
    }
    $target_frag_params = {
        'ensure'  => 'file',
        'content' => $target_config.wmflib::to_yaml,
        'tag'     => "prometheus::blackbox::check::icmp::${::site}::${prometheus_instance}::target",
    }

    wmflib::resource::export('prometheus::blackbox::module', $module_title, $title, $module_params)
    wmflib::resource::export('prometheus::rule', $alert_title, $title, $alert_rule_params)
    wmflib::resource::export('file', $target_file, $title, $target_frag_params)
}
