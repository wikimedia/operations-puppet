# SPDX-License-Identifier: Apache-2.0
# Uses the prometheus module and generates the specific configuration
# needed for WMF production

# This Prometheus instance is for metrics that come in from outside of the infrastructure.
# E.g. Statsv
class profile::prometheus::ext (
    String           $storage_retention              = lookup('profile::prometheus::ext::storage_retention', { 'default_value' => '730h'  }),
    String           $replica_label                  = lookup('prometheus::replica_label'),
    Boolean          $enable_thanos_upload           = lookup('profile::prometheus::enable_thanos_upload',      { 'default_value' => false   }),
    Optional[String] $thanos_min_time                = lookup('profile::prometheus::thanos::min_time', { 'default_value' => undef   }),
    Array            $alertmanagers                  = lookup('alertmanagers', {'default_value' => []}),
    Array            $alerting_relabel_configs_extra = lookup('profile::prometheus::ext::alerting_relabel_configs_extra'),
){
    $instance_name  = 'ext'
    $targets_path   = "/srv/prometheus/${instance_name}/targets"
    $listen_address = '127.0.0.1'
    $listen_port    = 9908

    $config_extra = {
        # All metrics will get an additional 'site' label when queried by
        # external systems (e.g. via federation)
        'external_labels' => {
            'site'       => $::site,
            'replica'    => $replica_label,
            'prometheus' => $instance_name,
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

    prometheus::server { $instance_name:
        listen_address                 => "${listen_address}:${listen_port}",
        storage_retention              => $storage_retention,
        global_config_extra            => $config_extra,
        scrape_configs_extra           => $scrape_configs_extra,
        alertmanagers                  => $alertmanagers.map |$a| { "${a}:9093" },
        alerting_relabel_configs_extra => $alerting_relabel_configs_extra,
    }

    prometheus::web { $instance_name:
        proxy_pass => "http://${listen_address}:${listen_port}/${instance_name}",
    }

    prometheus::rule { 'rules_ext.yml':
        instance => 'ext',
        source   => 'puppet:///modules/profile/prometheus/rules_ext.yml',
    }

    profile::thanos::sidecar { $instance_name:
        prometheus_port     => $listen_port,
        prometheus_instance => $instance_name,
        enable_upload       => $enable_thanos_upload,
        min_time            => $thanos_min_time,
    }

    prometheus::pint::source { 'ext':
        port => $listen_port,
    }
}
