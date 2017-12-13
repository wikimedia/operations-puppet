class profile::prometheus::wdqs_updater_exporter (
    $prometheus_nodes = hiera('prometheus_nodes'),
) {
    $prometheus_ferm_nodes = join($prometheus_nodes, ' ')
    $ferm_srange = "(@resolve((${prometheus_ferm_nodes})) @resolve((${prometheus_ferm_nodes}), AAAA))"

    require_package('prometheus-wdqs-updater-exporter')

    service { 'prometheus-wdqs-updater-exporter':
        ensure  => running,
    }

    ferm::service { 'prometheus-wdqs-updater-exporter':
        proto  => 'tcp',
        port   => '9194',
        srange => $ferm_srange,
    }
}
