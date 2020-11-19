# == Define: profile::prometheus::wmf_elasticsearch_exporter
#
# This adds some WMF specific metrics that are not available in the standard exporter.
#
# == Parameters
#
# [*prometheus_nodes*]
#   List of Prometheus master nodes.
# [*prometheus_port*]
#   Port used by the exporter for the listen socket
# [*elasticsearch_port*]
#   Port to monitor elasticsearch on
# [*indices_to_monitor*]
#   Array of elasticsearch indices or aliases to track metrics for
#
define profile::prometheus::wmf_elasticsearch_exporter(
    Array[Stdlib::Host] $prometheus_nodes,
    Stdlib::Port $prometheus_port,
    Stdlib::Port $elasticsearch_port,
    Array[String] $indices_to_monitor,
){

    $prometheus_nodes_ferm = join($prometheus_nodes, ' ')

    prometheus::wmf_elasticsearch_exporter { $title:
        prometheus_port    => $prometheus_port,
        elasticsearch_port => $elasticsearch_port,
        indices_to_monitor => $indices_to_monitor,
    }

    ferm::service { "prometheus_wmf_elasticsearch_exporter_${prometheus_port}":
        proto  => 'tcp',
        port   => $prometheus_port,
        srange => "(@resolve((${prometheus_nodes_ferm})) @resolve((${prometheus_nodes_ferm}), AAAA))",
    }

}
