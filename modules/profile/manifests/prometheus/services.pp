# SPDX-License-Identifier: Apache-2.0
# Uses the prometheus module and generates the specific configuration
# needed for WMF production
#
class profile::prometheus::services (
    String $replica_label                 = lookup('prometheus::replica_label'),
    Boolean $enable_thanos_upload         = lookup('profile::prometheus::enable_thanos_upload', { 'default_value' => false }),
    Optional[String] $thanos_min_time     = lookup('profile::prometheus::thanos::min_time', { 'default_value' => undef }),
    Array[Stdlib::Host] $alertmanagers    = lookup('alertmanagers', {'default_value' => []}),
    String $storage_retention             = lookup('profile::prometheus::services::storage_retention', {'default_value' => '4032h'}),
    Array $alerting_relabel_configs_extra = lookup('profile::prometheus::services::alerting_relabel_configs_extra'),
){

    $targets_path = '/srv/prometheus/services/targets'
    $port = 9903

    $config_extra = {
        # All metrics will get an additional 'site' label when queried by
        # external systems (e.g. via federation)
        'external_labels' => {
            'site'       => $::site,
            'replica'    => $replica_label,
            'prometheus' => 'services',
        },
    }

    $jmx_exporter_jobs = [
      {
        'job_name'        => 'cassandra',
        'scrape_timeout'  => '25s',
        'scheme'          => 'http',
        'file_sd_configs' => [
          { 'files' => [ "${targets_path}/cassandra_*.yaml" ]}
        ],
        # Drop restbase table/cf 'meta' metrics, not needed
        'metric_relabel_configs' => [
          { 'source_labels' => ['columnfamily'],
            'regex'  => 'meta',
            'action' => 'drop',
          },
          { 'source_labels' => ['table'],
            'regex'  => 'meta',
            'action' => 'drop',
          },
        ],
      },
    ]

    prometheus::jmx_exporter_config{ "cassandra_dev_${::site}":
        dest       => "${targets_path}/cassandra_dev_${::site}.yaml",
        class_name => 'role::cassandra_dev',
    }

    prometheus::jmx_exporter_config{ "cassandra_restbase_production_${::site}":
        dest       => "${targets_path}/cassandra_restbase_production_${::site}.yaml",
        class_name => 'role::restbase::production',
    }

    prometheus::jmx_exporter_config{ "cassandra_sessionstore_production_${::site}":
        dest       => "${targets_path}/cassandra_sessionstore_production_${::site}.yaml",
        class_name => 'role::sessionstore',
    }

    prometheus::server { 'services':
        listen_address                 => "127.0.0.1:${port}",
        storage_retention              => $storage_retention,
        scrape_configs_extra           => $jmx_exporter_jobs,
        global_config_extra            => $config_extra,
        alertmanagers                  => $alertmanagers.map |$a| { "${a}:9093" },
        alerting_relabel_configs_extra => $alerting_relabel_configs_extra,
    }

    prometheus::web { 'services':
        proxy_pass => "http://localhost:${port}/services",
    }

    profile::thanos::sidecar { 'services':
        prometheus_port     => $port,
        prometheus_instance => 'services',
        enable_upload       => $enable_thanos_upload,
        min_time            => $thanos_min_time,
    }

    prometheus::rule { 'rules_services.yml':
        instance => 'services',
        source   => 'puppet:///modules/profile/prometheus/rules_services.yml',
    }

    prometheus::pint::source { 'services':
        port => $port,
    }
}
