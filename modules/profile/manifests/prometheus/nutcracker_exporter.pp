class profile::prometheus::nutcracker_exporter (
    $prometheus_nodes = hiera('prometheus_nodes'),
) {
    $prometheus_ferm_nodes = join($prometheus_nodes, ' ')
    $ferm_srange = "(@resolve((${prometheus_ferm_nodes})) @resolve((${prometheus_ferm_nodes}), AAAA))"

    require_package('prometheus-nutcracker-exporter')

    service { 'prometheus-nutcracker-exporter':
        ensure  => running,
    }

    ferm::service { 'prometheus-nutcracker-exporter':
        proto  => 'tcp',
        port   => '9191',
        srange => $ferm_srange,
    }

    base::service_auto_restart { 'prometheus-nutcracker-exporter': }
}
