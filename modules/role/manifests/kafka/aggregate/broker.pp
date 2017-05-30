# == Class role::kafka::aggregate::broker
# Sets up a Kafka broker in an 'aggregate' Kafka cluster.
#
class role::kafka::aggregate::broker {
    system::role { 'role::kafka::aggregate::broker':
        description => "Kafka Broker in an 'aggregate' Kafka cluster",
    }

    include standard
    include base::firewall
    include profile::kafka::broker
}
