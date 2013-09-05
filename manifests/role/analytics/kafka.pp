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
#   include role::analytics::kafka::client
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
            'main'     => {
                'kraken-kafka.pmtpa.wmflabs'          => { 'id' => 1 },
                'kraken-kafka1.pmtpa.wmflabs'         => { 'id' => 2 },
            },
            'external' => {
                'kraken-kafka-external.pmtpa.wmflabs' => { 'id' => 10 },
            },
        }

        $log_dir = ['/var/spool/kafka']
    }
    # else Kafka cluster is based on $::site.
    else {
        $cluster = {
            'eqiad'   => {
                'analytics1021.eqiad.wmnet' => { 'id' => 21 },
                'analytics1022.eqiad.wmnet' => { 'id' => 22 },
            },
            # 'ulsfo' => { },
            # 'pmtpa' => { },
            # 'esams' => { },
        }

        # production Kafka uses JBOD log dir mounts.
        $log_dir = [
            '/var/spool/kafka/c',
            '/var/spool/kafka/d',
            '/var/spool/kafka/e',
            '/var/spool/kafka/f',
            '/var/spool/kafka/g',
            '/var/spool/kafka/h',
            '/var/spool/kafka/i',
            '/var/spool/kafka/j',
            '/var/spool/kafka/k',
            '/var/spool/kafka/l',
        ]
    }

    $hosts = $cluster[$kafka_cluster_name]
    $zookeeper_chroot = "/kafka-${kafka_cluster_name}"
}

# == Class role::analytics::kafka::client
#
class role::analytics::kafka::client inherits role::analytics::kafka::config {
    require role::analytics::zookeeper::config

    class { '::kafka':
        hosts            => $hosts,
        zookeeper_hosts  => $role::analytics::zookeeper::config::hosts_array,
        zookeeper_chroot => $zookeeper_chroot,
    }
}

# == Class role::analytics::kafka::server
#
class role::analytics::kafka::server inherits role::analytics::kafka::client {
    class { '::kafka::server':
        log_dir => $log_dir,
    }
}
