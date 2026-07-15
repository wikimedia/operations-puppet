# == Class role::kafka::jumbo::broker
# Sets up a Kafka broker in the 'jumbo' Kafka cluster.
#
class role::kafka::jumbo::broker {
    include profile::firewall
    include profile::kafka::broker
    include profile::base::production
}
