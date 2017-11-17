class profile::prometheus::druid_exporter (
    $prometheus_nodes = hiera('prometheus_nodes'),
) {
    prometheus::druid_exporter { 'default': }
    $prometheus_ferm_nodes = join($prometheus_nodes, ' ')
    $ferm_srange = "(@resolve((${prometheus_ferm_nodes})) @resolve((${prometheus_ferm_nodes}), AAAA))"

    ferm::service { 'prometheus-druid-exporter':
        proto  => 'tcp',
        port   => '8000',
        srange => $ferm_srange,
    }
}