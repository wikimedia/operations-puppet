# SPDX-License-Identifier: Apache-2.0
# Uses the prometheus module and generates the specific configuration
# needed for WMF production

# This Prometheus instance is for metrics that come in from outside of the infrastructure.
# E.g. Statsv
class profile::prometheus::ext (
    String          $replica_label                  = lookup('prometheus::replica_label'),
    Array           $alertmanagers                  = lookup('alertmanagers', {'default_value' => []}),
    Array           $alerting_relabel_configs_extra = lookup('profile::prometheus::ext::alerting_relabel_configs_extra'),
    Stdlib::HTTPUrl $http_proxy                     = lookup('http_proxy'),
){
    $instance = 'ext'
    $config = prometheus::instance_config($instance)
    $targets_path = $config['targets_path']
    $port = $config['port']
    $storage_retention = $config['retention_time']
    $storage_retention_size = $config['retention_size']
    $thanos_upload = $config['thanos_upload']

    $config_extra = {
        'external_labels' => {
            'site'       => $::site,
            'replica'    => $replica_label,
            'prometheus' => $instance,
        },
    }

    $scrape_configs_extra = [
        # StatsD Exporter on webperf
        {
            'job_name'        => 'statsv',
            'scheme'          => 'http',
            'file_sd_configs' => [
                { 'files' => [ "${targets_path}/statsv_*.yaml" ]}
            ],
        },
        # Jobs maintained by perf-team:
        {
            'job_name'        => 'webperf_navtiming',
            'scheme'          => 'http',
            'scrape_timeout'  => '40s', # temp bandaid for long-duration scrapes T326118
            'file_sd_configs' => [
                { 'files' => [ "${targets_path}/webperf_navtiming_*.yaml" ]}
            ],
        },
        {
            'job_name'        => 'webperf_arclamp',
            'scheme'          => 'http',
            'metrics_path'    => '/arclamp/metrics',
            'file_sd_configs' => [
                { 'files' => [ "${targets_path}/webperf_arclamp_*.yaml" ]}
            ],
        },

        # External metrics scraped via site webproxy
        {
            'job_name'        => 'ext_metrics',
            'scheme'          => 'https',
            'proxy_url'       => $http_proxy,
            'static_configs'  => [
                {
                    'targets' => [
                        'wikitech-static.wikimedia.org:443',
                    ],
                    'labels'  => {
                        '__metrics_path__' => '/wts-metrics',
                    },
                },
                {
                    'targets' => [
                        'releng-ci-metrics.wmcloud.org:443',
                    ],
                },
            ],
            'relabel_configs' => [
                { 'source_labels' => ['__address__'],
                  'target_label'  => 'instance',
                },
            ],
        },
    ]

    # statsd-exporter
    prometheus::class_config{ "statsv_${::site}":
        dest       => "${targets_path}/statsv_${::site}.yaml",
        class_name => 'profile::webperf::processors',
        port       => 9112,
    }

    prometheus::class_config{ "webperf_navtiming_${::site}":
        dest       => "${targets_path}/webperf_navtiming_${::site}.yaml",
        class_name => 'profile::webperf::processors',
        port       => 9230,
    }

    prometheus::class_config{ "webperf_arclamp_${::site}":
        dest       => "${targets_path}/webperf_arclamp_${::site}.yaml",
        class_name => 'profile::arclamp::processor',
        port       => 80,
    }

    prometheus::server { $instance:
        listen_address                 => "127.0.0.1:${port}",
        storage_retention              => $storage_retention,
        storage_retention_size         => $storage_retention_size,
        global_config_extra            => $config_extra,
        scrape_configs_extra           => $scrape_configs_extra,
        alertmanagers                  => $alertmanagers.map |$a| { "${a}:9093" },
        alerting_relabel_configs_extra => $alerting_relabel_configs_extra,
    }

    # Checks for alerting rules, defined in puppet
    prometheus::alert::import { $instance: }

    prometheus::rule { 'rules_ext.yml':
        instance => 'ext',
        source   => 'puppet:///modules/profile/prometheus/rules_ext.yml',
    }

    profile::thanos::sidecar { $instance:
        prometheus_port     => $port,
        prometheus_instance => $instance,
        enable_upload       => $thanos_upload,
    }

    prometheus::pint::source { $instance:
        port => $port,
    }
}
