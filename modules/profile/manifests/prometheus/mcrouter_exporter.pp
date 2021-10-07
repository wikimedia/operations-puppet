class profile::prometheus::mcrouter_exporter (
    Array[Stdlib::Host] $prometheus_nodes = lookup('prometheus_nodes'),
    Stdlib::Port        $mcrouter_port    = lookup('profile::prometheus::mcrouter_exporter::mcrouter_port'),
    Stdlib::Port        $listen_port      = lookup('profile::prometheus::mcrouter_exporter::listen_port'),
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

    profile::auto_restarts::service { 'prometheus-mcrouter-exporter': }
}
