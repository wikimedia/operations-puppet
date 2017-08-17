# Uses the prometheus module and generates the specific configuration
# needed for WMF production
#
# filtertags: labs-project-monitoring
class role::prometheus::services {
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

    $cassandra_jobs = [
      {
        'job_name'        => 'cassandra_restbase',
        'scheme'          => 'http',
        'file_sd_configs' => [
          { 'files' => [ "${targets_path}/cassandra_restbase_*.yaml" ]}
        ],
      },
    ]

    # Gather etcd metrics from machines exposing them via http
    prometheus::class_config{ "cassandra_restbase_${::site}":
        dest       => "${targets_path}/cassandra_restbase_${::site}.yaml",
        site       => $::site,
        class_name => 'cassandra::instance::monitoring',
        port       => 7800,
    }

    prometheus::server { 'services':
        storage_encoding      => '2',
        listen_address        => '127.0.0.1:9903',
        storage_retention     => $storage_retention,
        max_chunks_to_persist => $max_chunks_to_persist,
        memory_chunks         => $memory_chunks,
        scrape_configs_extra  => array_concat(
            $cassandra_jobs,
        ),
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
