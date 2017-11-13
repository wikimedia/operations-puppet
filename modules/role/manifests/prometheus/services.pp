# Uses the prometheus module and generates the specific configuration
# needed for WMF production
#
# filtertags: labs-project-monitoring
class role::prometheus::services {
    system::role { 'prometheus::services':
        description => 'Prometheus server (services)',
    }

    include ::standard
    include ::base::firewall

    $targets_path = '/srv/prometheus/services/targets'
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
        site       => $::site,
    }

    prometheus::jmx_exporter_config{ "cassandra_restbase_test_${::site}":
        dest       => "${targets_path}/cassandra_restbase_test_${::site}.yaml",
        class_name => 'role::restbase::test_cluster',
        site       => $::site,
    }

    prometheus::jmx_exporter_config{ "cassandra_restbase_production_ng_${::site}":
        dest       => "${targets_path}/cassandra_restbase_production_ng_${::site}.yaml",
        class_name => 'role::restbase::production_ng',
        site       => $::site,
    }

    prometheus::server { 'services':
        storage_encoding      => '2',
        listen_address        => '127.0.0.1:9903',
        storage_retention     => $storage_retention,
        max_chunks_to_persist => $max_chunks_to_persist,
        memory_chunks         => $memory_chunks,
        scrape_configs_extra  => $jmx_exporter_jobs,
        global_config_extra   => $config_extra,
    }

    prometheus::web { 'services':
        proxy_pass => 'http://localhost:9903/services',
    }

    prometheus::rule { 'rules_services.conf':
        instance => 'services',
        source   => 'puppet:///modules/role/prometheus/rules_services.conf',
    }
}
