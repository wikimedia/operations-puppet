class role::prometheus::memcached_exporter {
    prometheus::memcached_exporter { 'default': }

    $prometheus_nodes = hiera('prometheus_nodes')
    $prometheus_ferm_nodes = join($prometheus_nodes, ' ')

    ferm::service { 'prometheus-memcached-exporter':
        proto  => 'tcp',
        port   => '9150',
        srange => "(@resolve((${prometheus_ferm_nodes})) @resolve((${prometheus_ferm_nodes}), AAAA))"
    }
}
