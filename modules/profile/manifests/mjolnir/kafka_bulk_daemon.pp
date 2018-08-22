# = Class: profile::mjolnir::kafka_bulk_daemon
#
# This class sets up the MjoLniR kafka bulk daemon which facilitates
# loading scoring signals calculated in the analytics network into
# the production search clusters.
#
# Parameters
# $kafka_cluster - Name of kafka cluster to consume from
# $group_id - Kafka consumer group to join.
# $topics - Name of one or more kafka topics to consume from

class profile::mjolnir::kafka_bulk_daemon(
    String $kafka_cluster = hiera('profile::mjolnir::kafka_bulk_daemon::kafka_cluster'),
    String $group_id = hiera('profile::mjolnir::kafka_bulk_daemon::group_id'),
    Array[String] $topics = hiera('profile::mjolnir::kafka_bulk_daemon::topics'),
    Array[String] $prometheus_nodes = hiera('prometheus_nodes', []),
) {
    require ::profile::mjolnir

    $prometheus_port = 9170
    $kafka_config = kafka_config($kafka_cluster)
    ::systemd::service { 'mjolnir-kafka-bulk-daemon':
        content => template('profile/mjolnir/kafka-bulk-daemon.service.erb'),
    }

    ::base::service_auto_restart { 'mjolnir-kafka-bulk-daemon': }

    $prometheus_nodes_ferm = join($prometheus_nodes, ' ')
    ferm::service { 'mjolnir-bulk-metrics':
        proto  => 'tcp',
        port   => $prometheus_port,
        srange => "(@resolve((${prometheus_nodes_ferm})) @resolve((${prometheus_nodes_ferm}), AAAA))",
    }
}
