# == Class profile::eventbus
#
# Profile class for eventbus EventLogging service.
# This class includes topic configuration, mediawiki/event-schemas
# and an HTTP Produce service using eventlogging-service to produce
# to Kafka.
#
class profile::eventbus(
    $has_lvs                 = hiera('has_lvs', true),
    $kafka_message_max_bytes = hiera('kafka_message_max_bytes', 1048576),
    $statsd_host             = hiera('statsd'),
    $logstash_host           = hiera('logstash_host'),
    $logstash_port           = hiera('logstash_gelf_port', 12201),
) {
    class { '::eventschemas::mediawiki': }

    # for /srv/log dir creation
    class { '::service::configuration': }

    if $has_lvs {
        include ::profile::lvs::realserver
    }
    $config = kafka_config('main')

    class { '::eventlogging::dependencies': }

    # eventlogging code for eventbus is configured to deploy
    # from the eventlogging/eventbus deploy target
    # via scap/scap.cfg on the deployment host.
    scap::target { 'eventlogging/eventbus':
        deploy_user  => 'deploy-service',
        service_name => 'eventlogging-service-eventbus',
    }

    # The deploy-service user needs to be able to depool/pool
    # during the deployment.
    class { '::scap::conftool': }

    # Include eventlogging server configuration, including
    # /etc/eventlogging.d directories and eventlogging user and group.
    class { 'eventlogging::server':
        eventlogging_path => '/srv/deployment/eventlogging/eventbus',
        log_dir           => '/var/log/eventlogging',
    }

    $kafka_brokers_array = $config['brokers']['array']
    $kafka_base_uri      = inline_template('kafka:///<%= @kafka_brokers_array.join(":9092,") + ":9092" %>')

    $kafka_api_version = $config['api_version']
    # Append this to query params if set.
    $kafka_api_version_param = $kafka_api_version ? {
        undef   => '',
        default => "&api_version=${kafka_api_version}"
    }

    # The requests not only contain the message but also a small metadata overhead.
    # So if we want to produce a kafka_message_max_bytes payload the max request size should be a bit higher.
    # The 48564 value isn't arbitrary - it's the difference between default message.max.size and default max.request.size
    $producer_request_max_size = $kafka_message_max_bytes + 48564

    # When events are produced to kafka, the
    # topic produced to will be interpolated from the event
    # and this format.  We use datacenter prefixed topic names.
    # E.g.
    #   meta[topic] == mediawiki.revision_create
    # in eqiad will be produced to
    #   eqiad.mediawiki.revsion_create
    $kafka_output_uri = "${kafka_base_uri}?async=True&retries=3&topic=${::site}.{meta[topic]}${kafka_api_version_param}&max_request_size=${producer_request_max_size}&compression_type=snappy"
    $outputs = [$kafka_output_uri]

    $noisy_log_level = $::realm ? {
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
        source => 'puppet:///modules/profile/eventbus/failed_events.logrotate',
    }

    eventlogging::service::service { 'eventbus':
        schemas_path    => "${::eventschemas::mediawiki::path}/jsonschema",
        topic_config    => "${::eventschemas::mediawiki::path}/config/eventbus-topics.yaml",
        outputs         => $outputs,
        error_output    => 'file:///srv/log/eventlogging/eventlogging-service-eventbus.failed_events.log',
        statsd          => $statsd_host,
        statsd_prefix   => 'eventbus',
        logstash_host   => $logstash_host,
        logstash_port   => $logstash_port,
        # The service will be reloaded (SIGHUPed, not restarted)
        # if any of these resources change.
        # Reload if mediawiki/event-schemas has a change.
        reload_on       =>  Class['::eventschemas::mediawiki'],
        num_processes   => 16,
        noisy_log_level => $noisy_log_level,
        require         => [
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
