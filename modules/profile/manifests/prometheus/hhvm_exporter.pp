class profile::prometheus::hhvm_exporter (
    $prometheus_nodes = hiera('prometheus_nodes'),
) {
    prometheus::hhvm_exporter { 'default': }
}
