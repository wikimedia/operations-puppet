class profile::prometheus::mcrouter_exporter (
    Integer $mcrouter_port = 11211,
    $prometheus_nodes = hiera('prometheus_nodes'),
) {
    prometheus::mcrouter_exporter { 'default':
        args => "-mcrouter.address localhost:${mcrouter_port}",
    }

    $prometheus_ferm_nodes = join($prometheus_nodes, ' ')
    $ferm_srange = "(@resolve((${prometheus_ferm_nodes})) @resolve((${prometheus_ferm_nodes}), AAAA))"

    ferm::service { 'prometheus-mcrouter-exporter':
        proto  => 'tcp',
        port   => '9151',
        srange => $ferm_srange,
    }
}
