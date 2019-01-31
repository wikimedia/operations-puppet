class profile::prometheus::memcached_exporter (
    $prometheus_nodes = hiera('prometheus_nodes'),
    $arguments = hiera('profile::prometheus::memcached_exporter', ''),
) {
    prometheus::memcached_exporter { 'default':
        arguments => $arguments,
    }
    $prometheus_ferm_nodes = join($prometheus_nodes, ' ')
    $ferm_srange = "(@resolve((${prometheus_ferm_nodes})) @resolve((${prometheus_ferm_nodes}), AAAA))"

    ferm::service { 'prometheus-memcached-exporter':
        proto  => 'tcp',
        port   => '9150',
        srange => $ferm_srange,
    }
}