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
    # This allows labs to set the $::kafka_cluster global,
    # which will conditionally select labs hosts to include
    # in a Kafka cluster.  This allows us to test cross datacenter
    # broker mirroring with multiple clusters.
    $kafka_cluster_name = $::kafka_cluster ? {
        undef     => $::site,
        default   => $::kafka_cluster,
    }

    if ($::realm == 'labs') {
        # TODO: Make hostnames configurable via labs global variables.
        $cluster = {
            'main' => {
                'kraken-kafka.pmtpa.wmflabs'  => 1,
                'kraken-kafka1.pmtpa.wmflabs' => 2
            },
            'external' => {
                'kraken-kafka-external.pmtpa.wmflabs' => 10
            },
        }
    }
    # else Kafka cluster is based on $::site.
    else {
        $cluster = {
            'eqiad'   => {
                'analytics1021.eqiad.wmnet'  => 21,
                'analytics1022.eqiad.wmnet'  => 22,
            },
            # 'ulsfo' => { },
            # 'pmtpa' => { },
            # 'esams' => { },
        }
    }

    $hosts = $cluster[$kafka_cluster_name]
}

# == Class role::analytics::zookeeper::client
#
class role::analytics::kafka::client {
    require role::analytics::zookeeper::config

    class { '::kafka':
        hosts           => $role::analytics::zookeeper::config::hosts,
        zookeeper_hosts => $role::analytics::zookeeper::config::hosts_array,
    }
}

# == Class role::analytics::kafka::server
#
class role::analytics::kafka::server inherits role::analytics::kafka::client {
    class { '::kafka::server': }
}
