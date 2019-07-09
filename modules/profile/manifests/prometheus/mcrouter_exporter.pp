class profile::prometheus::mcrouter_exporter (
    Integer $mcrouter_port = hiera('mcrouter::port'),
    Integer $listen_port = hiera('profile::prometheus::mcrouter_exporter::listen_port', 9151),
    $prometheus_nodes = hiera('prometheus_nodes'),
) {
    prometheus::mcrouter_exporter { 'default':
        arguments => "-mcrouter.address localhost:${mcrouter_port} -web.listen-address :${listen_port} -mcrouter.server_metrics",
    }

    $prometheus_ferm_nodes = join($prometheus_nodes, ' ')
    $ferm_srange = "(@resolve((${prometheus_ferm_nodes})) @resolve((${prometheus_ferm_nodes}), AAAA))"

    ferm::service { 'prometheus-mcrouter-exporter':
        proto  => 'tcp',
        port   => $listen_port,
        srange => $ferm_srange,
    }

    base::service_auto_restart { 'prometheus-mcrouter-exporter': }
}
