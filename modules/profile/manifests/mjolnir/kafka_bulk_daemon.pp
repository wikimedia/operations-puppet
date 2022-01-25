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
# $priority_topics - Name of one of more kafka topics to consume from and give priority to.

class profile::mjolnir::kafka_bulk_daemon(
    String $kafka_cluster = lookup('profile::mjolnir::kafka_bulk_daemon::kafka_cluster'),
    String $group_id = lookup('profile::mjolnir::kafka_bulk_daemon::group_id'),
    String $es_cluster_endpoint = lookup('profile::mjolnir::kafka_bulk_daemon::es_cluster_endpoint', { 'default_value' => 'localhost:9200' }),
    Array[String] $topics = lookup('profile::mjolnir::kafka_bulk_daemon::topics'),
    Array[String] $priority_topics = lookup('profile::mjolnir::kafka_bulk_daemon::priority_topics'),
    Wmflib::Ensure $ensure = lookup('profile::mjolnir::kafka_bulk_daemon::ensure', { 'default_value' => 'present' }),
) {
    require ::profile::mjolnir

    if empty($topics) and empty($priority_topics) {
        fail('you must provide either "topics" or "priority_topics"')
    }

    $prometheus_port = 9170
    $kafka_config = kafka_config($kafka_cluster)
    ::systemd::service { 'mjolnir-kafka-bulk-daemon':
        ensure  => $ensure,
        content => template('profile/mjolnir/kafka-bulk-daemon.service.erb'),
    }

    ::profile::auto_restarts::service { 'mjolnir-kafka-bulk-daemon':
        ensure => $ensure,
    }
}
