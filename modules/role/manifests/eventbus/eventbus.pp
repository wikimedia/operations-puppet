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
# filtertags: labs-project-deployment-prep
class role::eventbus::eventbus {
    include ::base::firewall
    require ::eventschemas

    # for /srv/log dir creation
    require ::service::configuration

    if hiera('has_lvs', true) {
        include ::role::lvs::realserver
    }
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

    $kafka_api_version = $config['api_version']
    # Append this to query params if set.
    $kafka_api_version_param = $kafka_api_version ? {
        undef   => '',
        default => "&api_version=${kafka_api_version}"
    }

    $outputs = [
        # When events are produced to kafka, the
        # topic produced to will be interpolated from the event
        # and this format.  We use datacenter prefixed topic names.
        # E.g.
        #   meta[topic] == mediawiki.revision_create
        # in eqiad will be produced to
        #   eqiad.mediawiki.revsion_create
        #
        # We produce async=False so that we can be sure each request is ACKed by Kafka
        # before we return an HTTP status, and wait up to 10 seconds for this to happen.
        # In normal cases, this will be much much faster than 10 seconds, but during
        # broker restarts, it can take a few seconds for meta data and leadership
        # info to propagate to the kafka client.
        "${kafka_base_uri}?async=False&sync_timeout=10.0&topic=${::site}.{meta[topic]}${kafka_api_version_param}"
    ]

    $access_log_level = $::realm ? {
        'production' => 'WARNING',
        default      => 'INFO',
    }

    if !defined(File['/srv/log/eventlogging']) {
        file { '/srv/log/eventlogging':
            ensure => 'directory',
            mode   => '0755',
            owner  => 'eventlogging',
            group  => 'eventlogging',
        }
    }
    # Add logrotate for failed events log.  This shouldn't ever fill up,
    # but we want to be sure we don't have some fluke where we fill up
    # disks with error logs.
    logrotate::conf { 'eventlogging-service-eventbus.failed_events':
        ensure => 'present',
        source => 'puppet:///modules/role/eventbus/failed_events.logrotate',
    }

    eventlogging::service::service { 'eventbus':
        schemas_path     => "${::eventschemas::path}/jsonschema",
        topic_config     => "${::eventschemas::path}/config/eventbus-topics.yaml",
        outputs          => $outputs,
        error_output     => 'file:///srv/log/eventlogging/eventlogging-service-eventbus.failed_events.log',
        statsd           => hiera('statsd'),
        statsd_prefix    => 'eventbus',
        # The service will be reloaded (SIGHUPed, not restarted)
        # if any of these resources change.
        # Reload if mediawiki/event-schemas has a change.
        reload_on        =>  Class['::eventschemas'],
        num_processes    => 8,
        access_log_level => $access_log_level,
        require          => [
            File['/srv/log/eventlogging'],
            Logrotate::Conf['eventlogging-service-eventbus.failed_events'],
        ],
    }

    # Allow traffic to eventlogging-service on $port
    ferm::service { 'eventlogging-service-eventbus':
        proto  => 'tcp',
        port   => '8085',
        srange => '$DOMAIN_NETWORKS',
    }

}
