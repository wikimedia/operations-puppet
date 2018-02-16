# == class profile::kafka::burrow::main::codfw
#
# Consumer offset lag monitoring tool for the Kafka Main codfw cluster
#
class profile::kafka::burrow::main::codfw(
    $prometheus_nodes = hiera('prometheus_nodes'),
) {

    profile::kafka::burrow { 'main-codfw':
        http_port       => 8200,
    }

    profile::prometheus::burrow_exporter { 'main-codfw':
        burrow_addr      => 'localhost:8200',
        port             => 9600,
        prometheus_nodes => $prometheus_nodes,
    }
}
