# == Class role::kafka::test::broker
# Sets up a Kafka broker in the 'test' Kafka cluster.
#
class role::kafka::test::broker {
    include profile::firewall
    include profile::kafka::broker
    # Disabled unless profile::kafka::configurator::runner_host is set for the cluster
    include profile::kafka::configurator

    include profile::base::production
}
