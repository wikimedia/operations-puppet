# == Class role::eventstreams
#
# Role class for EventStreams HTTP service.
# This class includes the ::eventstreams role, and configures
# it to consume only specific topics from a specific Kafka cluster.
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
class role::eventstreams {
    system::role { 'role::eventstreams':
        description => 'Exposes configured event streams from Kafka to public internet via HTTP SSE',
    }

    $default_kafka_cluster_name = $::realm ? {
        'production' => 'analytics',
        'labs'       => 'main'
    }

    $kafka_cluster_name = hiera('role::eventstreams::port', $default_kafka_cluster_name)
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

    class { '::eventstreams':
        port        => $port,
        log_level   => $log_level,
        broker_list => $kafka_config['brokers']['string'],
        streams     => $streams,
    }
}
