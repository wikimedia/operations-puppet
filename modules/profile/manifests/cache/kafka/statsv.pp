# === Class profile::cache::kafka::statsv
#
# Sets up a varnishkafka logging endpoint for collecting
# application level metrics. We are calling this system
# statsv, as it is similar to statsd, but uses varnish
# as its logging endpoint.
#
# === Parameters
#
# [*cache_cluster*]
#   Used in when naming varnishkafka metrics.
#   Default:  hiera('cache::cluster')
#
# [*kafka_cluster_name*]
#   The name of the kafka cluster to use from the kafka_clusters hiera variable.
#   Since only one statsd instance is active at any given time, you should probably
#   set this explicitly to a fully qualified kafka cluster name (with DC suffix) that
#   is located in the same DC as the active statsd instance.
#
# [*monitoring_enabled*]
#   True if the varnishkafka instance should be monitored.  Default: false
#
class profile::cache::kafka::statsv(
    $cache_cluster      = hiera('cache::cluster'),
    $kafka_cluster_name = hiera('profile::cache::kafka::statsv::kafka_cluster_name'),
    $monitoring_enabled = hiera('profile::cache::kafka::statsv::monitoring_enabled', false),
)
{
    $kafka_config  = kafka_config($kafka_cluster_name)
    $kafka_brokers = $kafka_config['brokers']['array']

    $format  = "%{fake_tag0@hostname?${::fqdn}}x %{%FT%T@dt}t %{X-Client-IP@ip}o %{@uri_path}U %{@uri_query}q %{User-Agent@user_agent}i"

    varnishkafka::instance { 'statsv':
        brokers                     => $kafka_brokers,
        format                      => $format,
        format_type                 => 'json',
        topic                       => 'statsv',
        varnish_name                => 'frontend',
        varnish_svc_name            => 'varnish-frontend',
        # Only log webrequests to /beacon/statsv
        varnish_opts                => { 'q' => 'ReqURL ~ "^/beacon/statsv\?"' },
        # -1 means all brokers in the ISR must ACK this request.
        topic_request_required_acks => '-1',
    }

    # Make sure varnishes are configured and started for the first time
    # before the instances as well, or they fail to start initially...
    Service <| tag == 'varnish_instance' |> -> Varnishkafka::Instance['statsv']

    if $monitoring_enabled {
        # Generate icinga alert if varnishkafka is not running.
        nrpe::monitor_service { 'varnishkafka-statsv':
            description   => 'statsv Varnishkafka log producer',
            nrpe_command  => "/usr/lib/nagios/plugins/check_procs -c 1 -a '/usr/bin/varnishkafka -S /etc/varnishkafka/statsv.conf'",
            contact_group => 'admins,analytics',
            require       => Class['::varnishkafka'],
        }

        $graphite_metric_prefix = "varnishkafka.${::hostname}.statsv.${cache_cluster}"

        # Generate an alert if too many delivery report errors per minute
        # (logster only reports once a minute)
        monitoring::graphite_threshold { 'varnishkafka-statsv-kafka_drerr':
            ensure          => 'present',
            description     => 'Varnishkafka Statsv Delivery Errors per minute',
            dashboard_links => ['https://grafana.wikimedia.org/dashboard/db/varnishkafka?panelId=20&fullscreen&orgId=1&var-instance=statsv&var-host=All'],
            metric          => "derivative(transformNull(${graphite_metric_prefix}.varnishkafka.kafka_drerr, 0))",
            warning         => 0,
            critical        => 5000,
            # But only alert if a large percentage of the examined datapoints
            # are over the threshold.
            percentage      => 80,
            from            => '10min',
            require         => Logster::Job['varnishkafka-statsv'],
        }

        # Sets up Logster to read from the Varnishkafka instance stats JSON file
        # and report metrics to statsd.
        varnishkafka::monitor::statsd { 'statsv':
            graphite_metric_prefix => $graphite_metric_prefix,
            statsd_host_port       => hiera('statsd'),
        }
    }
}
