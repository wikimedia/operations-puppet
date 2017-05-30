# == Class role::kafka::simple::broker
# Sets up a Kafka broker in a 'simple' Kafka cluster.
# This is useful for spinning up simple Kafka clusters in labs.
#
class role::kafka::simple::broker {
    include profile::kafka::broker
}
