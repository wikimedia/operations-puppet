# Uses the prometheus module and generates the specific configuration
# needed for WMF production
#
# filtertags: labs-project-monitoring
class role::prometheus::k8s {
    include ::standard
    include ::base::firewall

    $targets_path = '/srv/prometheus/k8s/targets'
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

    prometheus::server { 'k8s':
        storage_encoding      => '2',
        listen_address        => '127.0.0.1:9906',
        storage_retention     => $storage_retention,
        max_chunks_to_persist => $max_chunks_to_persist,
        memory_chunks         => $memory_chunks,
        global_config_extra   => $config_extra,
    }

    prometheus::web { 'k8s':
        proxy_pass => 'http://localhost:9906/k8s',
    }

    prometheus::rule { 'rules_k8s.conf':
        instance => 'k8s',
        source   => 'puppet:///modules/role/prometheus/rules_k8s.conf',
    }
}
