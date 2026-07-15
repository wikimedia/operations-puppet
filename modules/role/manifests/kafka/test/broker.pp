# == Class role::kafka::test::broker
# Sets up a Kafka broker in the 'test' Kafka cluster.
#
class role::kafka::test::broker {
    include profile::firewall
    include profile::kafka::broker
    include profile::base::production
}
