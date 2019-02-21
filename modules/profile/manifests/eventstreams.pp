# == Class profile::eventstreams
#
# Profile that installs EventStreams HTTP service.
# This class includes the eventstreams nodejs service, and configures
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
# == Parameters
# [*kafka_cluster_name*]
#   Name of the kafka cluster
#
# [*streams*]
#   Streams to follow
#
# [*rdkafka_config*]
#   Additional configuration for the kafka library
#
# [*monitoring_enabled*]
#   If true, an active Eventstreams endpoint (/v2/recentchange) will be periodically
#   checked for new messages.  If none are found, an alert will be triggered.
#   Default: false
#
# filtertags: labs-project-deployment-prep
#
class profile::eventstreams(
    $kafka_cluster_name = hiera('profile::eventstreams::kafka_cluster_name'),
    $streams            = hiera('profile::eventstreams::streams'),
    $rdkafka_config     = hiera('profile::eventstreams::rdkafka_config', {}),
    $monitoring_enabled = hiera('profile::eventstreams::monitoring_enabled', false),
) {
    $kafka_config = kafka_config($kafka_cluster_name)
    $broker_list = $kafka_config['brokers']['string']
    service::packages { 'eventstreams':
        pkgs     => ['librdkafka++1', 'librdkafka1'],
    }

    $port = 8092
    service::node { 'eventstreams':
        enable            => true,
        port              => $port,
        has_spec          => false, # TODO: figure out how to monitor stream with spec x-amples
        deployment        => 'scap3',
        deployment_config => true,
        deployment_vars   => {
            site           => $::site,
            broker_list    => $broker_list,
            rdkafka_config => $rdkafka_config,
            streams        => $streams,
        },
        auto_refresh      => false,
        init_restart      => false,
        environment       => {
            'UV_THREADPOOL_SIZE' => 128,
        },
        require           => Service::Packages['eventstreams'],
    }

    if $monitoring_enabled {
        # Check that The recentchange stream is delivering events on this host
        class { '::profile::eventstreams::monitoring':
            stream_url => "http://${::fqdn}:${port}/v2/stream/recentchange",
            # Since this is a local check, we need to use nrpe so the remote
            # icinga server can request the status.
            use_nrpe   => true,
        }
    }
}
