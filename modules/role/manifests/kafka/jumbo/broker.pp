# == Class role::kafka::jumbo::broker
# Sets up a Kafka broker in the 'jumbo' Kafka cluster.
#
class role::kafka::jumbo::broker {
    system::role { 'role::kafka::jumbo::broker':
        description => "Kafka Broker in a 'jumbo' Kafka cluster",
    }

    include standard
    include base::firewall
    include profile::kafka::broker
}
