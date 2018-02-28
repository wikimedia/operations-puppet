# === Define role::cache::kafka::eventlogging
#
# Sets up a varnishkafka logging endpoint for collecting
# analytics events coming from external clients.
#
# More info: https://wikitech.wikimedia.org/wiki/Analytics/EventLogging
#
# === Parameters
#
# [*varnish_name*]
#   The name of the varnish instance to read shared logs from.
#   Default 'frontend'
# [*varnish_svc_name*]
#   The name of the init unit for the above.
#   Default 'varnish-frontend'
# [*kafka_protocol_version*]
#   Kafka API version to use, needed for brokers < 0.10
#   https://issues.apache.org/jira/browse/KAFKA-3547
#
class role::cache::kafka::eventlogging(
    # TODO: This whole class is being refactored in https://gerrit.wikimedia.org/r/#/c/403067/
    # This temporarily fixes a puppet error in deployment-prep.
    $kafka_cluster_name     = hiera('profile::cache::kafka::eventlogging::kafka_cluster_name', 'analytics')
    $varnish_name           = 'frontend',
    $varnish_svc_name       = 'varnish-frontend',
    $kafka_protocol_version = '0.9.0.1',
)
{
    $kafka_config = kafka_config($kafka_cluster_name)
    $kafka_brokers = $kafka_config['brokers']['array']

    # Set varnish.arg.q or varnish.arg.m according to Varnish version
    $varnish_opts = { 'q' => 'ReqURL ~ "^/(beacon/)?event(\.gif)?\?"' }

    varnishkafka::instance { 'eventlogging':
        # FIXME - top-scope var without namespace, will break in puppet 2.8
        # lint:ignore:variable_scope
        brokers                     => $kafka_brokers,
        # lint:endignore
        # Note that this format uses literal tab characters.
        format                      => '%q	%l	%n	%{%FT%T}t	%{X-Client-IP}o	"%{User-agent}i"',
        format_type                 => 'string',
        topic                       => 'eventlogging-client-side',
        varnish_name                => $varnish_name,
        varnish_svc_name            => $varnish_svc_name,
        varnish_opts                => $varnish_opts,
        topic_request_required_acks => '1',
        force_protocol_version      => $kafka_protocol_version,
    }

    include ::standard

    # Generate icinga alert if varnishkafka is not running.
    nrpe::monitor_service { 'varnishkafka-eventlogging':
        description   => 'eventlogging Varnishkafka log producer',
        nrpe_command  => "/usr/lib/nagios/plugins/check_procs -c 1 -a '/usr/bin/varnishkafka -S /etc/varnishkafka/eventlogging.conf'",
        contact_group => 'admins,analytics',
        require       => Class['::varnishkafka'],
    }

    $cache_type = hiera('cache::cluster')
    $graphite_metric_prefix = "varnishkafka.${::hostname}.eventlogging.${cache_type}"

    # Sets up Logster to read from the Varnishkafka instance stats JSON file
    # and report metrics to statsd.
    varnishkafka::monitor::statsd { 'eventlogging':
        graphite_metric_prefix => $graphite_metric_prefix,
        statsd_host_port       => hiera('statsd'),
    }

    Service <| tag == 'varnish_instance' |> -> Varnishkafka::Instance <| |>
}
