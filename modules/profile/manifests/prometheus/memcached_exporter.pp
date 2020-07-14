class profile::prometheus::memcached_exporter (
    Array[Stdlib::Host] $prometheus_nodes = lookup('prometheus_nodes'),
    String              $arguments        = lookup('profile::prometheus::memcached_exporter::arguments'),
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
