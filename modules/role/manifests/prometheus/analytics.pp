# Uses the prometheus module and generates the specific configuration
# needed for WMF production
#
# filtertags: labs-project-monitoring
class role::prometheus::analytics {
    include ::standard
    include ::base::firewall

    $targets_path = '/srv/prometheus/analytics/targets'
    $storage_retention = hiera('prometheus::server::storage_retention', '2190h0m0s')
    $max_chunks_to_persist = hiera('prometheus::server::max_chunks_to_persist', '524288')
    $memory_chunks = hiera('prometheus::server::memory_chunks', '1048576')

    $config_extra = {
        # All metrics will get an additional 'site' label when queried by
        # external systems (e.g. via federation)
        'external_labels' => {
            'site' => $::site,
        },
    }

    $jmx_exporter_jobs = [
      {
        'job_name'        => 'kafka',
        'scheme'          => 'http',
        'file_sd_configs' => [
          { 'files' => [ "${targets_path}/kafka_*.yaml" ]}
        ],
      },
    ]

    prometheus::jmx_exporter_config{ "kafka_jumbo_broker_${::site}":
        dest       => "${targets_path}/kafka_jumbo_broker_${::site}.yaml",
        class_name => 'role::kafka::jumbo::broker',
        site       => $::site,
    }

    prometheus::server { 'analytics':
        storage_encoding      => '2',
        listen_address        => '127.0.0.1:9904',
        storage_retention     => $storage_retention,
        max_chunks_to_persist => $max_chunks_to_persist,
        memory_chunks         => $memory_chunks,
        scrape_configs_extra  => $jmx_exporter_jobs,
        global_config_extra   => $config_extra,
    }

    prometheus::web { 'analytics':
        proxy_pass => 'http://localhost:9904/analytics',
    }

    prometheus::rule { 'rules_analytics.conf':
        instance => 'analytics',
        source   => 'puppet:///modules/role/prometheus/rules_analytics.conf',
    }
}
