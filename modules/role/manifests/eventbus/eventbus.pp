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
    require ::role::kafka::main::config

    # eventlogging code for eventbus is configured to deploy
    # from the eventlogging/eventbus deploy target
    # via scap/scap.cfg on the deployment host.
    scap::target { 'eventlogging/eventbus':
        deploy_user       => 'eventlogging',
        public_key_source => "puppet:///modules/eventlogging/deployment/eventlogging_rsa.pub.${::realm}",
        service_name      => 'eventlogging-service-eventbus',
        manage_user       => false,
    }

    $kafka_brokers_array = $role::kafka::main::config::brokers_array
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

    $eventlogging_path = '/srv/deployment/eventlogging/eventbus'
    # TODO: Allow configuration of more than one service daemon process?
    eventlogging::service::service { 'eventbus':
        eventlogging_path => $eventlogging_path,
        # TODO: Deploy mediawiki/event-schemas separately
        # from the submodule in EventLogging repo?
        schemas_path      => "${::eventschemas::path}/jsonschema",
        topic_config      => "${::eventschemas::path}/config/eventbus-topics.yaml",
        outputs           => $outputs,
        statsd            => hiera('statsd'),
        statsd_prefix     => 'eventbus',
        # The service will be reloaded (SIGHUPed, not restarted)
        # if any of these resources change.
        # Reload if mediawiki/event-schemas has a change.
        reload_on         =>  Class['::eventschemas'],
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
