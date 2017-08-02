# == Class role::kafka::aggregate::broker
# Sets up a Kafka broker in the 'jumbo' Kafka cluster.
#
class role::kafka::jumbo::broker {
    system::role { 'role::kafka::aggregate::broker':
        description => "Kafka Broker in an 'jumbo' Kafka cluster",
    }

    include standard
    include base::firewall
    include profile::kafka::broker
}
