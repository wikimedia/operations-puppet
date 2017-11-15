# === Define role::cache::kafka::statsv
#
# Sets up a varnishkafka logging endpoint for collecting
# application level metrics. We are calling this system
# statsv, as it is similar to statsd, but uses varnish
# as its logging endpoint.
#
# === Parameters
#
# [*varnish_name*]
#   The name of the varnish instance to read shared logs from.
#   Default 'frontend'
# [*varnish_svc_name*]
#   The name of the init unit for the above.
#   Default 'varnish-frontend'
# [*kafka_cluster_name*]
#   The name of the kafka cluster to use from the kafka_clusers hiera variable.
#   Default: 'main'
#
class role::cache::kafka::statsv(
    $varnish_name           = 'frontend',
    $varnish_svc_name       = 'varnish-frontend',
    $kafka_cluster_name     = 'main',
) inherits role::cache::kafka
{
    $kafka_config = kafka_config($kafka_cluster_name)
    $kafka_brokers = $kafka_config['brokers']['array']

    $format  = "%{fake_tag0@hostname?${::fqdn}}x %{%FT%T@dt}t %{X-Client-IP@ip}o %{@uri_path}U %{@uri_query}q %{User-Agent@user_agent}i"

    # Set varnish.arg.q or varnish.arg.m according to Varnish version
    $varnish_opts = { 'q' => 'ReqURL ~ "^/beacon/statsv\?"' }
    $conf_template = 'varnishkafka/varnishkafka_v4.conf.erb'

    varnishkafka::instance { 'statsv':
        brokers                     => $kafka_brokers,
        # lint:endignore
        format                      => $format,
        format_type                 => 'json',
        # Prefix statsv topic with datacenter name.
        topic                       => "${::site}.statsv",
        varnish_name                => $varnish_name,
        varnish_svc_name            => $varnish_svc_name,
        varnish_opts                => $varnish_opts,
        # -1 means all brokers in the ISR must ACK this request.
        topic_request_required_acks => '-1',
        conf_template               => $conf_template,
        force_protocol_version      => $kafka_config['api_version'],
    }

    include ::standard

    # Generate icinga alert if varnishkafka is not running.
    nrpe::monitor_service { 'varnishkafka-statsv':
        description   => 'statsv Varnishkafka log producer',
        nrpe_command  => "/usr/lib/nagios/plugins/check_procs -c 1 -a '/usr/bin/varnishkafka -S /etc/varnishkafka/statsv.conf'",
        contact_group => 'admins,analytics',
        require       => Class['::varnishkafka'],
    }

    $cache_type = hiera('cache::cluster')
    $graphite_metric_prefix = "varnishkafka.${::hostname}.statsv.${cache_type}"

    # Sets up Logster to read from the Varnishkafka instance stats JSON file
    # and report metrics to statsd.
    varnishkafka::monitor::statsd { 'statsv':
        graphite_metric_prefix => $graphite_metric_prefix,
        statsd_host_port       => hiera('statsd'),
    }
}
