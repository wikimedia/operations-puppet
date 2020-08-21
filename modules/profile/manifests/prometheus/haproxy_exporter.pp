class profile::prometheus::haproxy_exporter(
    Array[Stdlib::Host] $prometheus_nodes = lookup('prometheus_nodes'),
    Stdlib::Port $listen_port = lookup('listen_port'),
){

    $prometheus_nodes_ferm = join($prometheus_nodes, ' ')

    class {
        '::prometheus::haproxy_exporter':
            listen_port => $listen_port
    }

    ferm::service { 'haproxy_exporter':
        proto  => 'tcp',
        port   => $listen_port,
        srange => "(@resolve((${prometheus_nodes_ferm})) @resolve((${prometheus_nodes_ferm}), AAAA))",
    }
}
