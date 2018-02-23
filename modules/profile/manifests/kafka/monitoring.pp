# == class profile::kafka::cluster::monitoring
#
# Tools to monitor and expose metrics about a Kafka cluster
#
class profile::kafka::monitoring(
    $config           = hiera('profile::kafka::monitoring::config'),
    $clusters         = hiera('profile::kafka::monitoring::clusters'),
    $prometheus_nodes = hiera('prometheus_nodes'),
) {

    profile::kafka::burrow { $clusters:
        monitoring_config => $config,
        prometheus_nodes  => $prometheus_nodes,
    }
}
