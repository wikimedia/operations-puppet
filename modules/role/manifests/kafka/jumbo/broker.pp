# == Class role::kafka::jumbo::broker
# Sets up a Kafka broker in the 'jumbo' Kafka cluster.
#
class role::kafka::jumbo::broker {
    system::role { 'role::kafka::jumbo::broker':
        description => "Kafka Broker in a 'jumbo' Kafka cluster",
    }

    # Something in labs is including standard.  Only include if not already defined.
    if !defined(Class['::standard']) {
        include ::standard
    }
    include base::firewall
    include profile::kafka::broker

    # This is temporary until T182993 is completed
    include ::role::ipsec
    class { '::ferm::ipsec_allow': }

    # Mirror main-eqiad -> jumbo-eqiad
    include profile::kafka::mirror
}
