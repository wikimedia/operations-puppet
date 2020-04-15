class profile::prometheus::nic_saturation_exporter (
    $prometheus_nodes = lookup('prometheus_nodes'),
) {
    class {'prometheus::nic_saturation_exporter': }

    $prometheus_ferm_nodes = join($prometheus_nodes, ' ')
    $ferm_srange = "(@resolve((${prometheus_ferm_nodes})) @resolve((${prometheus_ferm_nodes}), AAAA))"

    ferm::service { 'prometheus-nic-saturation-exporter':
        proto  => 'tcp',
        port   => '9710',
        srange => $ferm_srange,
    }
}
