class role::prometheus::hhvm_exporter {
    prometheus::hhvm_exporter { 'default': }

    $prometheus_nodes = hiera('prometheus_nodes')
    $prometheus_ferm_nodes = join($prometheus_nodes, ' ')
    $ferm_srange = "(@resolve((${prometheus_ferm_nodes})) @resolve((${prometheus_ferm_nodes}), AAAA))"

    ferm::service { 'prometheus-hhvm-exporter':
        proto  => 'tcp',
        port   => '9192',
        srange => $ferm_srange,
    }
}
