# == Class: eventstreams
#
# === Parameters
#
# [*broker_list*]
#   Comma-separated list of Kafka broker URIs
#
# [*streams*]
#   Hash of stream route config and their composite topics. E.g.
#
#   streamName1:
#       topics: [topicA, topicB]
#   streamName2:
#       topics: [topicC, topicD]
#
# [*log_level*]
#   Log level for service logger. Default: info
#
class eventstreams(
    $broker_list,
    $streams,
    $log_level = 'info'
) {

    service::packages { 'eventstreams':
        pkgs     => ['librdkafka++1', 'librdkafka1'],
    }

    service::node { 'eventstreams':
        enable            => true,
        port              => 6947,
        healthcheck_url   => '',
        has_spec          => false, # I should make one!
        deployment        => 'scap3',
        deployment_config => true,
        deployment_vars   => {
            log_level      => $log_level,
            site           => $::site,
            broker_list    => $broker_list,
            streams        => $streams,
        },
        auto_refresh      => false,
        init_restart      => false,
        environment       => {
            'UV_THREADPOOL_SIZE' => 128
        },
    }

}
