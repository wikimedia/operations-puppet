# SPDX-License-Identifier: Apache-2.0
# Uses the prometheus module and generates the specific configuration
# needed for WMF production
#
class profile::prometheus::services (
    String $replica_label                 = lookup('prometheus::replica_label'),
    Array[Stdlib::Host] $alertmanagers    = lookup('alertmanagers', {'default_value' => []}),
    Array $alerting_relabel_configs_extra = lookup('profile::prometheus::services::alerting_relabel_configs_extra'),
){
    $instance = 'services'
    $config = prometheus::instance_config($instance)
    $targets_path = $config['targets_path']
    $port = $config['port']
    $storage_retention = $config['retention_time']
    $storage_retention_size = $config['retention_size']
    $thanos_upload = $config['thanos_upload']

    $config_extra = {
        # All metrics will get an additional 'site' label when queried by
        # external systems (e.g. via federation)
        'external_labels' => {
            'site'       => $::site,
            'replica'    => $replica_label,
            'prometheus' => $instance,
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

    $restbase_jobs = [
        {
            'job_name'        => 'restbase',
            'scheme'          => 'http',
            'file_sd_configs' => [
                { 'files' => [ "${targets_path}/restbase_*.yaml"] },
            ],
        },
    ]

    prometheus::class_config{ "restbase_${::site}":
        dest       => "${targets_path}/restbase_${::site}.yaml",
        class_name => 'profile::restbase',
        port       => 9102,
    }

    prometheus::server { $instance:
        listen_address                 => "127.0.0.1:${port}",
        storage_retention              => $storage_retention,
        storage_retention_size         => $storage_retention_size,
        scrape_configs_extra           => [ $jmx_exporter_jobs, $restbase_jobs ].flatten,
        global_config_extra            => $config_extra,
        alertmanagers                  => $alertmanagers.map |$a| { "${a}:9093" },
        alerting_relabel_configs_extra => $alerting_relabel_configs_extra,
    }

    profile::thanos::sidecar { $instance:
        prometheus_port     => $port,
        prometheus_instance => $instance,
        enable_upload       => $thanos_upload,
    }

    prometheus::rule { 'rules_services.yml':
        instance => 'services',
        source   => 'puppet:///modules/profile/prometheus/rules_services.yml',
    }

    prometheus::pint::source { $instance:
        port => $port,
    }
}
