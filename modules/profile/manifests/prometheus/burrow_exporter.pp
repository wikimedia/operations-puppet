# Prometheus Burrow (Kafka Consumer lag monitor) metrics exporter.
#
# === Parameters
#
# [*$burrow_addr*]
#  The ip:port combination of the Burrow instance to poll data from.
#
# [*$hostname*]
#  The host to listen on. The host/port combination will also be used to generate Prometheus
#  targets.
#
# [*$port*]
#  The port to listen on.
#
define profile::prometheus::burrow_exporter (
    $prometheus_nodes,
    $burrow_addr = 'localhost:8000',
    $hostname = $::hostname,
    $port = '8000',
) {
    prometheus::burrow_exporter { $title:
        burrow_addr  => $burrow_addr,
        metrics_addr => "${hostname}:${port}",
        interval     => 30,
    }

    $prometheus_ferm_nodes = join($prometheus_nodes, ' ')
    $ferm_srange = "(@resolve((${prometheus_ferm_nodes})) @resolve((${prometheus_ferm_nodes}), AAAA))"

    ferm::service { 'prometheus-burrow_exporter':
        proto  => 'tcp',
        port   => $port,
        srange => $ferm_srange,
    }
}