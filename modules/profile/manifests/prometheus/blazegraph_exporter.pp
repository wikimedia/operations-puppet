class profile::prometheus::blazegraph_exporter (
    $prometheus_nodes = hiera('prometheus_nodes'),
) {
    $prometheus_ferm_nodes = join($prometheus_nodes, ' ')
    $ferm_srange = "(@resolve((${prometheus_ferm_nodes})) @resolve((${prometheus_ferm_nodes}), AAAA))"

    require_package('prometheus-blazegraph-exporter')

    service { 'prometheus-blazegraph-exporter':
        ensure  => running,
    }

    ferm::service { 'prometheus-blazegraph-exporter':
        proto  => 'tcp',
        port   => '9193',
        srange => $ferm_srange,
    }

    base::service_auto_restart { 'prometheus-blazegraph-exporter': }
}
