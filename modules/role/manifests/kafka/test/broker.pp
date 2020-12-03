# == Class role::kafka::test::broker
# Sets up a Kafka broker in the 'test' Kafka cluster.
#
class role::kafka::test::broker {
    system::role { 'role::kafka::test::broker':
        description => "Kafka Broker in a 'test' Kafka cluster",
    }

    include profile::base::firewall
    include profile::kafka::broker
    include profile::kafka::mirror

    include ::profile::standard
}
