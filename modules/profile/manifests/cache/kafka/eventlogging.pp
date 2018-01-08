# === Class profile::cache::kafka::eventlogging
#
# Sets up a varnishkafka logging endpoint for collecting
# analytics events coming from external clients.
#
# More info: https://wikitech.wikimedia.org/wiki/Analytics/EventLogging
#
# === Parameters
#
# [*kafka_cluster_name*]
#   Name of the Kafka cluster in the kafka_clusters hash to be passed to the
#   kafka_config() function.  Default: jumbo.
#
# [*monitoring_enabled*]
#   True if the varnishkafka instance should be monitored.
#
# [*cache_cluster*]
#   The name of the cache cluster.
#
# [*statsd*]
#   The host to send statsd data to.
#
class profile::cache::kafka::eventlogging(
    $kafka_cluster_name = hiera('profile::cache::kafka::eventlogging::kafka_cluster_name', 'jumbo'),
    $monitoring_enabled = hiera('profile::cache::kafka::eventlogging::monitoring_enabled', false),
    $cache_cluster      = hiera('cache::cluster'),
    $statsd             = hiera('statsd'),
) {
    # Include this class to get key and certificate for varnishkafka
    # to produce to Kafka over SSL/TLS.
    require ::profile::cache::kafka::certificate

    # Set varnish.arg.q or varnish.arg.m according to Varnish version
    $varnish_opts = { 'q' => 'ReqURL ~ "^/(beacon/)?event(\.gif)?\?"' }

    $config = kafka_config($kafka_cluster_name)
    # Array of kafka brokers in jumbo-eqiad with SSL port 9093
    $kafka_brokers = $config['brokers']['ssl_array']

    $topic            = "webrequest_${cache_cluster}_test"
    $varnish_name     = 'frontend'
    $varnish_svc_name = 'varnish-frontend'

    varnishkafka::instance { 'eventlogging':
        brokers                     => $kafka_brokers,
        # Note that this format uses literal tab characters.
        # The '-' in this string used to be %{X-Client-IP@ip}o.
        # EventLogging clientIp logging has been removed as part of T128407.
        format                      => '%q	%l	%n	%{%FT%T}t	-	"%{User-agent}i"',
        format_type                 => 'string',
        topic                       => 'eventlogging-client-side',
        varnish_name                => $varnish_name,
        varnish_svc_name            => $varnish_svc_name,
        varnish_opts                => $varnish_opts,
        topic_request_required_acks => '1',
    }

    if $monitoring_enabled {
        # Generate icinga alert if varnishkafka is not running.
        nrpe::monitor_service { 'varnishkafka-eventlogging':
            description   => 'eventlogging Varnishkafka log producer',
            nrpe_command  => "/usr/lib/nagios/plugins/check_procs -c 1 -a '/usr/bin/varnishkafka -S /etc/varnishkafka/eventlogging.conf'",
            contact_group => 'admins,analytics',
            require       => Varnishkafka::Instance['eventlogging'],
        }

        $graphite_metric_prefix = "varnishkafka.${::hostname}.eventlogging.${cache_cluster}"

        # Sets up Logster to read from the Varnishkafka instance stats JSON file
        # and report metrics to statsd.
        varnishkafka::monitor::statsd { 'eventlogging':
            graphite_metric_prefix => $graphite_metric_prefix,
            statsd_host_port       => $statsd,
        }
    }

    # Make sure varnishes are configured and started for the first time
    # before the instances as well, or they fail to start initially...
    Service <| tag == 'varnish_instance' |> -> Varnishkafka::Instance['eventlogging']
}
