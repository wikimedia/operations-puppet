# == Class role::eventbus
#
# Role class for eventbus EventLogging service.
# This class includes topic configuration, mediawiki/event-schemas
# and an HTTP Produce service using eventlogging-service to produce
# to Kafka.
#
# You can configure the underlying eventlogging-service
# using hiera settings for the eventlogging::service::service class.
#
# TODO: Move this class back to role::eventbus once
# https://phabricator.wikimedia.org/T119042 works.
#
class role::eventbus::eventbus {
    # TODO: Use a different deploy target for eventbus's eventlogging code?
    require ::eventlogging

    # Infer Kafka cluster configuration from this class.
    # TODO: Use production kafka cluster configuration
    # when it exists.
    require ::role::analytics::kafka::config

    file { '/etc/eventbus':
        ensure => 'directory',
    }

    file { '/etc/eventbus/topics.yaml':
        source => 'puppet:///modules/role/eventbus/topics.yaml',
    }

    $kafka_brokers_array = $role::analytics::kafka::config::brokers_array
    $kafka_base_uri      = inline_template('kafka:///<%= @kafka_brokers_array.join(":9092,") + ":9092" %>')

    $outputs = [
        "${kafka_base_uri}?async=False"
    ]

    # TODO: Allow configuration of more than one service daemon process?
    eventlogging::service::service { 'eventbus':
        # TODO: Deploy mediawiki/event-schemas separately
        # from the submodule in EventLogging repo?
        schemas_path => "${::eventlogging::package::path}/config/schemas/jsonschema",
        topic_config => '/etc/eventbus/topics.yaml',
        outputs      => $outputs,
    }
}
