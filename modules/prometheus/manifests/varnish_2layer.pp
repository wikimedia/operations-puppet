# Generate Prometheus targets configuration for varnish frontend and backend
# instances, using data from get_clusters().

define prometheus::varnish_2layer(
    $targets_path,
    $cache_name,
) {
    prometheus::varnish_config{ "${cache_name}_backend":
        dest    => "${targets_path}/varnish-${cache_name}_${::site}_backend.yaml",
        site    => $::site,
        cluster => "varnish_${cache_name}",
        port    => '9331',
        labels  => {'layer' => 'backend' },
    }

    prometheus::varnish_config{ "${cache_name}_frontend":
        dest    => "${targets_path}/varnish-${cache_name}_${::site}_frontend.yaml",
        site    => $::site,
        cluster => "varnish_${cache_name}",
        port    => '9131',
        labels  => {'layer' => 'frontend' },
    }
}
