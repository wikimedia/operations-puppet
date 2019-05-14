# == Define: profile::prometheus::elasticsearch_exporter
#
# Configures a prometheus elasticsearch exporter and sets up appropriate
# firewall rules for collection from the exporter.
#
# == Parameters
#
# [*prometheus_nodes*]
#   List of Prometheus master nodes.
# [*prometheus_port*]
#   Port used by the exporter for the listen socket
# [*elasticsearch_port*]
#   Port to monitor elasticsearch on
#
define profile::prometheus::elasticsearch_exporter(
    Array[String] $prometheus_nodes,
    Stdlib::Port $prometheus_port,
    Stdlib::Port $elasticsearch_port,
) {
    $prometheus_nodes_ferm = join($prometheus_nodes, ' ')

    prometheus::elasticsearch_exporter { "localhost:${elasticsearch_port}":
        elasticsearch_port => $elasticsearch_port,
        prometheus_port    => $prometheus_port,
    }

    ferm::service { "prometheus_elasticsearch_exporter_${prometheus_port}":
        proto  => 'tcp',
        port   => $prometheus_port,
        srange => "(@resolve((${prometheus_nodes_ferm})) @resolve((${prometheus_nodes_ferm}), AAAA))",
    }

}
