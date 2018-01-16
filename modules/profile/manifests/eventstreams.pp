# == Class profile::eventstreams
#
# Profile that installs EventStreams HTTP service.
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
# filtertags: labs-project-deployment-prep
class profile::eventstreams(
    $kafka_cluster_name = hiera('profile::eventstreams::kafka_cluster_name'),
    $streams = hiera('profile::eventstreams::streams'),
    $rdkafka_config = hiera('profile::eventstreams::rdkafka_config')
) {
    $kafka_config = kafka_config($kafka_cluster_name)
    $broker_list = $kafka_config['brokers']['string']


    $librdkafka_version = $::lsbdistcodename ? {
        'jessie'  => '0.9.4-1~jessie1',
        'stretch' => '0.9.3-1',
    }

    # We are only installing librdkafka packages here, so make all
    # in scope package resources ensure the version.
    # See: https://phabricator.wikimedia.org/T185016
    Package {
        ensure => $librdkafka_version
    }
    # Need to use package resource directly, so we can ensure version.
    if !defined(Package['librdkafka1']) {
        package { 'librdkafka1': }
    }
    if !defined(Package['librdkafka++1']) {
        package { 'librdkafka++1': }
    }

    # TODO: restore use of service::packages when we no longer need to
    # ensure a specific librdkafka version.
    # service::packages { 'eventstreams':
    #     pkgs     => ['librdkafka++1', 'librdkafka1'],
    # }

    service::node { 'eventstreams':
        enable            => true,
        port              => 8092,
        has_spec          => false, # TODO: figure out how to monitor stream with spec x-amples
        deployment        => 'scap3',
        deployment_config => true,
        deployment_vars   => {
            log_level      => 'info',
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
}
