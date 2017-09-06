# == Class role::kafka::jumbo::broker
# Sets up a Kafka broker in the 'jumbo' Kafka cluster.
#
class role::kafka::jumbo::broker {
    system::role { 'role::kafka::jumbo::broker':
        description => "Kafka Broker in a 'jumbo' Kafka cluster",
    }

    # Don't use ganglia
    class { '::standard':
        has_ganglia => false
    }
    include base::firewall

    $kafka_cluster_name = 'jumbo'
    $n = kafka_cluster_name($kafka_cluster_name)
    notify { "kafka cluster name is given as ${kafka_cluster_name}, function returns ${n}": }
    # include profile::kafka::broker
}
