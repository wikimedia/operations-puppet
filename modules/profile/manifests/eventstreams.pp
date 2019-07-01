# == Class profile::eventstreams
#
# Profile that installs EventStreams HTTP service.
# This class includes the eventstreams nodejs service, and configures
# it to consume only specific topics from a specific Kafka cluster.
#
# == Parameters
# [*kafka_cluster_name*]
#   Name of the kafka cluster
#
# [*streams*]
#   Streams to follow
#
# [*client_ip_connection_limit*]
#   If provided, each evenstreams worker will only allow
#   this number of connections from the same X-Client-IP.
#   See also https://phabricator.wikimedia.org/T226808#5292059
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
    $kafka_cluster_name         = hiera('profile::eventstreams::kafka_cluster_name'),
    $streams                    = hiera('profile::eventstreams::streams'),
    $client_ip_connection_limit = hiera('profile::eventstreams::client_ip_connection_limit', undef),
    $rdkafka_config             = hiera('profile::eventstreams::rdkafka_config', {}),
    $monitoring_enabled         = hiera('profile::eventstreams::monitoring_enabled', false),
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
            site                       => $::site,
            broker_list                => $broker_list,
            client_ip_connection_limit => $client_ip_connection_limit,
            rdkafka_config             => $rdkafka_config,
            streams                    => $streams,
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
