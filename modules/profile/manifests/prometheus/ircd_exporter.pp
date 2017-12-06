class profile::prometheus::ircd_exporter (
    $prometheus_nodes = hiera('prometheus_nodes'),
) {
    $prometheus_ferm_nodes = join($prometheus_nodes, ' ')
    $ferm_srange = "(@resolve((${prometheus_ferm_nodes})) @resolve((${prometheus_ferm_nodes}), AAAA))"

    require_package('prometheus-ircd-exporter')

    service { 'prometheus-ircd-exporter':
        ensure  => running,
    }

    ferm::service { 'prometheus-ircd-exporter':
        proto  => 'tcp',
        port   => '9197',
        srange => $ferm_srange,
    }
}
