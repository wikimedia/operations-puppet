# == Class role::kafka::jumbo::broker
# Sets up a Kafka broker in the 'jumbo' Kafka cluster.
#
class role::kafka::jumbo::broker {
    system::role { 'role::kafka::jumbo::broker':
        description => "Kafka Broker in a 'jumbo' Kafka cluster",
    }

    # Don't use ganglia.
    # Something in labs is including standard.  Only include if not already defined.
    if !defined(Class['::standard']) {
        class { '::standard':
            has_ganglia => false
        }
    }
    include base::firewall
    include profile::kafka::broker
}
