# == class profile::kafka::burrow::main::eqiad
#
# Consumer offset lag monitoring tool for the Kafka Main eqiad cluster
#
class profile::kafka::burrow::main::eqiad(
    $prometheus_nodes = hiera('prometheus_nodes'),
) {

    profile::kafka::burrow { 'main-eqiad':
        http_port       => 8100,
    }

    profile::prometheus::burrow_exporter { 'main-eqiad':
        burrow_addr      => 'localhost:8100',
        port             => 9500,
        prometheus_nodes => $prometheus_nodes,
    }
}
