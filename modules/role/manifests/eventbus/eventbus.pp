# == Class role::eventbus
#
# Role class for eventbus EventLogging service.
# This class includes topic configuration, mediawiki/event-schemas
# and an HTTP Produce service using eventlogging-service to produce
# to Kafka.
#
# TODO: Move this class back to role::eventbus once
# https://phabricator.wikimedia.org/T119042 works.
#
class role::eventbus::eventbus {
    require ::eventschemas

    $config = kafka_config('main')

    # eventlogging code for eventbus is configured to deploy
    # from the eventlogging/eventbus deploy target
    # via scap/scap.cfg on the deployment host.
    eventlogging::deployment::target { 'eventbus':
        service_name        => 'eventlogging-service-eventbus',
    }

    # Include eventlogging server configuration, including
    # /etc/eventlogging.d directories and eventlogging user and group.
    class { 'eventlogging::server':
        # eventlogging::deployment::target { 'eventbus':
        # Will deploy eventlogging code to
        # /srv/deployment/eventlogging/eventbus.
        eventlogging_path => '/srv/deployment/eventlogging/eventbus',
    }

    $kafka_brokers_array = $config['brokers']['array']
    $kafka_base_uri      = inline_template('kafka:///<%= @kafka_brokers_array.join(":9092,") + ":9092" %>')

    $outputs = [
        # When events are produced to kafka, the
        # topic produced to will be interpolated from the event
        # and this format.  We use datacenter prefixed topic names.
        # E.g.
        #   meta[topic] == mediawiki.revision_create
        # in eqiad will be produced to
        #   eqiad.mediawiki.revsion_create
        "${kafka_base_uri}?async=False&topic=${::site}.{meta[topic]}"
    ]


    $access_log_level = $::realm ? {
        'production' => 'WARNING',
        default      => 'INFO',
    }

    # TODO: Allow configuration of more than one service daemon process?
    eventlogging::service::service { 'eventbus':
        schemas_path     => "${::eventschemas::path}/jsonschema",
        topic_config     => "${::eventschemas::path}/config/eventbus-topics.yaml",
        outputs          => $outputs,
        statsd           => hiera('statsd'),
        statsd_prefix    => 'eventbus',
        # The service will be reloaded (SIGHUPed, not restarted)
        # if any of these resources change.
        # Reload if mediawiki/event-schemas has a change.
        reload_on        =>  Class['::eventschemas'],
        num_processes    => 8,
        access_log_level => $access_log_level
    }

    # Allow traffic to eventlogging-service on $port
    ferm::service { 'eventlogging-service-eventbus':
        proto  => 'tcp',
        port   => '8085',
        srange => '$INTERNAL',
    }

    if $::realm == 'production' {
        include lvs::realserver
    }
}
