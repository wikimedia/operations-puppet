# == Class role::eventstreams
#
# Role class for EventStreams HTTP service.
# This class includes the ::eventstreams role, and configures
# it to consume only specific topics from a specific Kafka cluster.
#
# NOTE: eventstreams is configured to use the 'analytics-eqiad' Kafka cluster
# in both eqiad and codfw.  This means that codfw eventstreams will be doing
# cross DC consumption.  Since we don't have a beefy non critical 'aggregate/analytics'
# Kafka cluster in codfw (yet), we don't have a good Kafka cluster that can back
# eventstreams in codfw.  We could back it with the main-codfw cluster, but there
# are issues with doing that:
#
# 1. main Kafka clusters are for critical prod services, and we don't want some unknown
#    bug/exploit taking down the main clusters.  This service 'exposes' Kafka to the internet.
#
# 2. change-prop requires that topics have only one partition, which means we can't spread
#    consumer load for a given topic across multiple brokers.  change-prop uses the main
#    Kafka clusters.  In the analytics/aggregate cluster, we can add partitions to the topics.
#
# In the future, we would like to rename analytics-eqiad to something more appropriate, perhaps
# aggregate-eqiad, and also set up an aggregate-codfw Kafka cluster.
#
# == Hiera Variables
# [*role::eventstreams::kafka_cluster_name*]
#   Default: 'analytics' in production, 'main' in labs.
#
# [*role::eventstreams::port*]
#   Default: 8092
#
# [*role::eventstreams::log_level*]
#   Default: info
#
# [*role::eventstreams::streams*]
#   Default: test and revision-create.
#
# [*role::eventstreams::rdkafka_config*]
#   Default: {}
#
class role::eventstreams {
    system::role { 'role::eventstreams':
        description => 'Exposes configured event streams from Kafka to public internet via HTTP SSE',
    }

    # Default to analytics-eqiad in production, for both eqiad and codfw eventstreams.
    $default_kafka_cluster_name = $::realm ? {
        'production' => 'analytics',
        'labs'       => 'main'
    }

    $kafka_cluster_name = hiera('role::eventstreams::kafka_cluster_name', $default_kafka_cluster_name)
    $kafka_config       = kafka_config($kafka_cluster_name)

    $port      = hiera('role::eventstreams::port', 8092)
    $log_level = hiera('role::eventstreams::log_level', 'info')

    $streams = hiera('role::eventstreams::streams', {
        'test' => {
            'topics' => ["${::site}.test.event"]
        },
        'revision-create' => {
            'topics' => ["${::site}.mediawiki.revision-create"]
        }
    })

    # Any extra librdkafka configuration
    $rdkafka_config = hiera('role::eventstreams::rdkafka_config', {})

    class { '::eventstreams':
        port           => $port,
        log_level      => $log_level,
        broker_list    => $kafka_config['brokers']['string'],
        streams        => $streams,
        rdkafka_config => $rdkafka_config,
    }
}
