# == Class role::kafka::simple::broker
# Sets up a Kafka broker in a 'simple' Kafka cluster.
# This is useful for spinning up simple Kafka clusters in labs.
#
class role::kafka::simple::broker {
    system::role { 'role::kafka::simple::broker':
        description => "Kafka Broker in a 'simple' Kafka cluster",
    }

    include standard
    include profile::base::firewall
    include profile::kafka::broker
}
