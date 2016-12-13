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
# [*port*]
#   Default: 8092
#
# [*log_level*]
#   Log level for service logger. Default: info
#
# [*rdkafka_config*]
#   Extra librdkafka configuration to provide to node-rdkafka.  Default: {}
#
class eventstreams(
    $broker_list,
    $streams,
    $port           = 8092,
    $log_level      = 'info',
    $rdkafka_config = {},
) {
    service::packages { 'eventstreams':
        pkgs     => ['librdkafka++1', 'librdkafka1'],
    }

    service::node { 'eventstreams':
        enable            => true,
        port              => $port,
        has_spec          => false, # TODO: figure out how to monitor stream with spec x-amples
        deployment        => 'scap3',
        deployment_config => true,
        deployment_vars   => {
            log_level      => $log_level,
            site           => $::site,
            broker_list    => $broker_list,
            rdkafka_config => $rdkafka_config
            streams        => $streams,
        },
        auto_refresh      => false,
        init_restart      => false,
        environment       => {
            'UV_THREADPOOL_SIZE' => 128
        },
        require           => Service::Packages['eventstreams']
    }

}
