# role/analytics/kafka.pp
#
# Role classes for Analytics Kakfa nodes.
# These role classes will configure Kafka properly in either
# the Analytics labs or Analytics production environments.
#
# Usage:
#
# If you only need the Kafka package and configs to use the
# Kafka client to talk to Kafka Broker Servers:
#
#   include role::analytics::zookeeper::client
#
# If you want to set up a Kafka Broker Server
#   include role::analytics::kafka::server
#
class role::analytics::kafka::config {
    # TODO: Make this configurable via labs global variables.
    $labs_hosts = {
        'kraken-kafka.pmtpa.wmflabs' => 1,
    }

    $production_hosts = {
        'analytics1021.eqiad.wmnet'  => 21,
        'analytics1022.eqiad.wmnet'  => 22,
    }

    $hosts = $::realm ? {
        'labs'       => $labs_hosts,
        'production' => $production_hosts,
    }
}

# == Class role::analytics::zookeeper::client
#
class role::analytics::kafka::client {
    require role::analytics::zookeeper::config

    class { '::kafka':
        hosts           => $hosts,
        zookeeper_hosts => $role::analytics::zookeeper::config::hosts_array,
    }
}

# == Class role::analytics::kafka::server
#
class role::analytics::kafka::server inherits role::analytics::kafka::client {
    class { '::kafka::server': }
}
