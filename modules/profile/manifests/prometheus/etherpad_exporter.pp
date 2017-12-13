class profile::prometheus::etherpad_exporter (
    $prometheus_nodes = hiera('prometheus_nodes'),
) {
    $prometheus_ferm_nodes = join($prometheus_nodes, ' ')
    $ferm_srange = "(@resolve((${prometheus_ferm_nodes})) @resolve((${prometheus_ferm_nodes}), AAAA))"

    require_package('prometheus-etherpad-exporter')

    service { 'prometheus-etherpad-exporter':
        ensure  => running,
    }

    ferm::service { 'prometheus-etherpad-exporter':
        proto  => 'tcp',
        port   => '9198',
        srange => $ferm_srange,
    }
}
