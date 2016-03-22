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
    require ::eventlogging
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

    file { '/etc/eventbus':
        ensure => 'directory',
    }

    file { '/etc/eventbus/topics.yaml':
        source => 'puppet:///modules/role/eventbus/topics.yaml',
    }

    $kafka_brokers_array = $role::kafka::main::config::brokers_array
    $kafka_base_uri      = inline_template('kafka:///<%= @kafka_brokers_array.join(":9092,") + ":9092" %>')

    $outputs = [
        "${kafka_base_uri}?async=False"
    ]

    $eventlogging_path = '/srv/deployment/eventlogging/eventbus'
    # TODO: Allow configuration of more than one service daemon process?
    eventlogging::service::service { 'eventbus':
        eventlogging_path => $eventlogging_path,
        # TODO: Deploy mediawiki/event-schemas separately
        # from the submodule in EventLogging repo?
        schemas_path      => "${::eventschemas::path}/jsonschema",
        topic_config      => '/etc/eventbus/topics.yaml',
        outputs           => $outputs,
        statsd            => hiera('statsd'),
        statsd_prefix     => 'eventbus',
        # The service will be reloaded (SIGHUPed, not restarted)
        # if any of these resources change.
        reload_on         => [
            # Reload if mediawiki/event-schemas has a change.
            Class['::eventschemas'],
            # Reload if topic config has a change.
            File['/etc/eventbus/topics.yaml'],
        ]
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
