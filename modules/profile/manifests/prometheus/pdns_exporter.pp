class profile::prometheus::pdns_exporter (
    $prometheus_nodes = hiera('prometheus_nodes'),
    $prometheus_nodes_extra = hiera('prometheus_nodes_extra', []),
) {
    $prometheus_ferm_nodes = join($prometheus_nodes + $prometheus_nodes_extra, ' ')
    $ferm_srange = "(@resolve((${prometheus_ferm_nodes})) @resolve((${prometheus_ferm_nodes}), AAAA))"

    require_package('prometheus-pdns-exporter')

    service { 'prometheus-pdns-exporter':
        ensure  => running,
    }

    ferm::service { 'prometheus-pdns-exporter':
        proto  => 'tcp',
        port   => '9192',
        srange => $ferm_srange,
    }
}
