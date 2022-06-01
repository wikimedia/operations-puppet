# Uses the prometheus module and generates the specific configuration
# needed for WMF production
#
class profile::prometheus::services (
    String $replica_label                 = lookup('prometheus::replica_label', { 'default_value' => 'unset' }),
    Boolean $enable_thanos_upload         = lookup('profile::prometheus::enable_thanos_upload', { 'default_value' => false }),
    Optional[String] $thanos_min_time     = lookup('profile::prometheus::thanos::min_time', { 'default_value' => undef }),
    Array[Stdlib::Host] $alertmanagers    = lookup('alertmanagers', {'default_value' => []}),
    String $storage_retention             = lookup('prometheus::server::storage_retention', {'default_value' => '4032h'}),
    Integer $max_chunks_to_persist        = lookup('prometheus::server::max_chunks_to_persist', {'default_value' => 524288}),
    Integer $memory_chunks                = lookup('prometheus::server::memory_chunks', {'default_value' => 1048576}),
    Boolean $disable_compaction           = lookup('profile::prometheus::thanos::disable_compaction', { 'default_value' => false }),
    Array $alerting_relabel_configs_extra = lookup('profile::prometheus::services::alerting_relabel_configs_extra'),
){

    $targets_path = '/srv/prometheus/services/targets'

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

    prometheus::jmx_exporter_config{ "cassandra_restbase_dev_${::site}":
        dest       => "${targets_path}/cassandra_restbase_dev_${::site}.yaml",
        class_name => 'role::restbase::dev_cluster',
    }

    prometheus::jmx_exporter_config{ "cassandra_restbase_production_${::site}":
        dest       => "${targets_path}/cassandra_restbase_production_${::site}.yaml",
        class_name => 'role::restbase::production',
    }

    prometheus::jmx_exporter_config{ "cassandra_sessionstore_production_${::site}":
        dest       => "${targets_path}/cassandra_sessionstore_production_${::site}.yaml",
        class_name => 'role::sessionstore',
    }

    prometheus::jmx_exporter_config{ "cassandra_maps_production_${::site}":
        dest       => "${targets_path}/cassandra_maps_production_${::site}.yaml",
        class_name => 'profile::maps::cassandra',
    }

    $max_block_duration = ($enable_thanos_upload and $disable_compaction) ? {
        true    => '2h',
        default => '24h',
    }

    prometheus::server { 'services':
        listen_address                 => '127.0.0.1:9903',
        storage_retention              => $storage_retention,
        max_chunks_to_persist          => $max_chunks_to_persist,
        memory_chunks                  => $memory_chunks,
        scrape_configs_extra           => $jmx_exporter_jobs,
        global_config_extra            => $config_extra,
        min_block_duration             => '2h',
        max_block_duration             => $max_block_duration,
        alertmanagers                  => $alertmanagers.map |$a| { "${a}:9093" },
        alerting_relabel_configs_extra => $alerting_relabel_configs_extra,
    }

    prometheus::web { 'services':
        proxy_pass => 'http://localhost:9903/services',
    }

    profile::thanos::sidecar { 'services':
        prometheus_port     => 9903,
        prometheus_instance => 'services',
        enable_upload       => $enable_thanos_upload,
        min_time            => $thanos_min_time,
    }

    prometheus::rule { 'rules_services.yml':
        instance => 'services',
        source   => 'puppet:///modules/profile/prometheus/rules_services.yml',
    }
}
