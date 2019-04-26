# === Class profile::cache::kafka::eventlogging
#
# Sets up a varnishkafka logging endpoint for collecting
# analytics events coming from external clients.
#
# More info: https://wikitech.wikimedia.org/wiki/Analytics/EventLogging
#
# === Parameters
#
# [*cache_cluster*]
#   The name of the cache cluster.
#
# [*statsd*]
#   The host to send statsd data to.
#
# [*kafka_cluster_name*]
#   Name of the Kafka cluster in the kafka_clusters hash to be passed to the
#   kafka_config() function.
#
# [*ssl_enabled*]
#   If true, the Kafka cluster needs to be configured with SSL support.
#   profile::cache::kafka::certificate will be included, and certs used from it.
#   Default: false
#
# [*monitoring_enabled*]
#   True if the varnishkafka instance should be monitored.  Default: false
#
class profile::cache::kafka::eventlogging(
    $cache_cluster      = hiera('cache::cluster'),
    $statsd             = hiera('statsd'),
    $kafka_cluster_name = hiera('profile::cache::kafka::eventlogging::kafka_cluster_name'),
    $ssl_enabled        = hiera('profile::cache::kafka::eventlogging::ssl_enabled', false),
    $monitoring_enabled = hiera('profile::cache::kafka::eventlogging::monitoring_enabled', false),
) {
    $kafka_config = kafka_config($kafka_cluster_name)

    if $ssl_enabled {
        $kafka_brokers = $kafka_config['brokers']['ssl_array']

        # Include this class to get key and certificate for varnishkafka
        # to produce to Kafka over SSL/TLS.
        require ::profile::cache::kafka::certificate
        $ssl_ca_location          = $::profile::cache::kafka::certificate::ssl_ca_location
        $ssl_key_password         = $::profile::cache::kafka::certificate::ssl_key_password
        $ssl_key_location         = $::profile::cache::kafka::certificate::ssl_key_location
        $ssl_certificate_location = $::profile::cache::kafka::certificate::ssl_certificate_location
        $ssl_cipher_suites        = $::profile::cache::kafka::certificate::ssl_cipher_suites
        $ssl_curves_list          = $::profile::cache::kafka::certificate::ssl_curves_list
        $ssl_sigalgs_list         = $::profile::cache::kafka::certificate::ssl_sigalgs_list
    }
    else {
        $kafka_brokers = $kafka_config['brokers']['array']

        $ssl_ca_location          = undef
        $ssl_key_password         = undef
        $ssl_key_location         = undef
        $ssl_certificate_location = undef
        $ssl_cipher_suites        = undef
        $ssl_curves_list          = undef
        $ssl_sigalgs_list         = undef
    }

    # TEMPORARY HACK to aid in migration to kafka jumbo.
    # this will be removed once varnishkafka instances use jumbo instead of analytics.
    $force_protocol_version  = $kafka_cluster_name ? {
        'analytics' => '0.9.0.1',
        default     => undef,
    }

    varnishkafka::instance { 'eventlogging':
        brokers                     => $kafka_brokers,
        # Note that this format uses literal tab characters.
        # The '-' in this string used to be %{X-Client-IP@ip}o.
        # EventLogging clientIp logging has been removed as part of T128407.
        format                      => '%q	%l	%n	%{%FT%T}t	%{X-Client-IP}o	"%{User-agent}i"',
        format_type                 => 'string',
        compression_codec           => 'snappy',
        topic                       => 'eventlogging-client-side',
        varnish_name                => 'frontend',
        varnish_svc_name            => 'varnish-frontend',
        # Only listen and log requests to /beacon/event(.gif)?
        varnish_opts                => { 'q' => 'ReqURL ~ "^/(beacon/)?event(\.gif)?\?"' },
        topic_request_required_acks => '1',
        #TLS/SSL config
        ssl_enabled                 => $ssl_enabled,
        ssl_ca_location             => $ssl_ca_location,
        ssl_key_password            => $ssl_key_password,
        ssl_key_location            => $ssl_key_location,
        ssl_certificate_location    => $ssl_certificate_location,
        ssl_cipher_suites           => $ssl_cipher_suites,
        ssl_curves_list             => $ssl_curves_list,
        ssl_sigalgs_list            => $ssl_sigalgs_list,
        force_protocol_version      => $force_protocol_version,
    }

    if $monitoring_enabled {
        # Aggregated alarms for delivery errors are defined in icinga::monitor::analytics

        # Generate icinga alert if varnishkafka is not running.
        nrpe::monitor_service { 'varnishkafka-eventlogging':
            description   => 'eventlogging Varnishkafka log producer',
            nrpe_command  => "/usr/lib/nagios/plugins/check_procs -c 1:1 -a '/usr/bin/varnishkafka -S /etc/varnishkafka/eventlogging.conf'",
            contact_group => 'admins,analytics',
            require       => Varnishkafka::Instance['eventlogging'],
            notes_url     => 'https://wikitech.wikimedia.org/wiki/Analytics/Systems/Varnishkafka',
        }

        # Sets up Logster to read from the Varnishkafka instance stats JSON file
        # and report metrics to statsd.
        varnishkafka::monitor::statsd { 'eventlogging':
            graphite_metric_prefix => "varnishkafka.${::hostname}.eventlogging.${cache_cluster}",
            statsd_host_port       => $statsd,
        }
    }

    # Make sure varnishes are configured and started for the first time
    # before the instances as well, or they fail to start initially...
    Service <| tag == 'varnish_instance' |> -> Varnishkafka::Instance['eventlogging']
}
