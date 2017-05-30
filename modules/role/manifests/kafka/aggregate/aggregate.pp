# == Class role::kafka::aggregate::broker
# Sets up a Kafka broker in an 'aggregate' Kafka cluster.
class role::kafka::aggregate::broker {
    include profile::kafka::broker
}
