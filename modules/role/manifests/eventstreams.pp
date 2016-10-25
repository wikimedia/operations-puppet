# == Class role::eventstreams
#
# Role class for EventStreams HTTP service.
# This class includes the ::eventstreams role, and configures
# it to consume only specific topics from a specific Kafka cluster.
#
# == Hiera Variables
# [*eventstreams_kafka_cluster_name*]
#   Default: 'analytics' in production, 'main' in labs.
#
# [*eventstreams_port*]
#   Default: 8092
#
# [*eventstreams_log_level*]
#   Default: info
#
# [*eventstreams_streams*]
#   Default: test and revision-create.
#
class role::eventstreams {
    system::role { 'role::eventstreams':
        description => 'Exposes configured event streams from Kafka to public internet via HTTP SSE',
    }

    $default_kafka_cluster_name = $::realm ? {
        'production' => 'analytics',
        'labs'       => 'main'
    }

    $kafka_cluster_name = hiera('eventstreams_kafka_cluster_name', $default_kafka_cluster_name)
    $kafka_config       = kafka_config($kafka_cluster_name)

    $port      = hiera('eventstreams_port', 8092)
    $log_level = hiera('eventstreams_log_level', 'info')

    $streams = hiera('eventstreams_streams', {
        'test' => {
            'topics' => ["${::site}.test.event"]
        },
        'revision-create' => {
            'topics' => ["${::site}.mediawiki.revision-create"]
        }
    })

    class { '::eventstreams':
        port        => $port,
        log_level   => $log_level,
        broker_list => $kafka_config['brokers']['string'],
        streams     => $streams,
    }
}
