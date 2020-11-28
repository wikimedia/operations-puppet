# == class profile::kafka::cluster::monitoring
#
# Tools to monitor and expose metrics about a Kafka cluster
#
class profile::kafka::monitoring(
    Hash[String,Hash] $config             = lookup('profile::kafka::monitoring::config'),
    Array[String] $clusters               = lookup('profile::kafka::monitoring::clusters'),
    Array[Stdlib::Host] $prometheus_nodes = lookup('prometheus_nodes'),
) {

    profile::kafka::burrow { $clusters:
        monitoring_config => $config,
        prometheus_nodes  => $prometheus_nodes,
    }
}
