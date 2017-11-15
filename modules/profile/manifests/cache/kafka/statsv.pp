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
#   The name of the kafka cluster to use from the kafka_clusers hiera variable.
#   Default: 'main'
#
class profile::cache::kafka::statsv(
    $cache_type         = hiera('cache::cluster'),
    $kafka_cluster_name = hiera('profile::cache::kafka::statsv::kafka_cluster_name', 'main')
)
{
    # The kafka cluster config will ultimately be selected using the kafka_datacenter_map hiera
    # hash via the kafka_cluster_name() puppet function.  E.g. if this is a varnishkafka instance
    # running in esams, and $kafka_cluster_name is 'main', likely 'main-eqiad' kafka cluster will be
    # picked, as it is the  geographically closest main Kafka cluster to esams.
    $kafka_config  = kafka_config($kafka_cluster_name)
    $kafka_brokers = $kafka_config['brokers']['array']

    $format  = "%{fake_tag0@hostname?${::fqdn}}x %{%FT%T@dt}t %{X-Client-IP@ip}o %{@uri_path}U %{@uri_query}q %{User-Agent@user_agent}i"

    varnishkafka::instance { 'statsv':
        brokers                     => $kafka_brokers,
        # lint:endignore
        format                      => $format,
        format_type                 => 'json',
        topic                       => 'statsv',
        varnish_name                => 'frontend',
        varnish_svc_name            => 'varnish-frontend',
        # Only log webrequests to /beacon/statsv
        varnish_opts                => { 'q' => 'ReqURL ~ "^/beacon/statsv\?"' },
        # -1 means all brokers in the ISR must ACK this request.
        topic_request_required_acks => '-1',
        conf_template               => 'varnishkafka/varnishkafka_v4.conf.erb',
        force_protocol_version      => $kafka_config['api_version'],
    }

    # Make sure varnishes are configured and started for the first time
    # before the instances as well, or they fail to start initially...
    Service <| tag == 'varnish_instance' |> -> Varnishkafka::Instance['statsv']

    # Generate icinga alert if varnishkafka is not running.
    nrpe::monitor_service { 'varnishkafka-statsv':
        description   => 'statsv Varnishkafka log producer',
        nrpe_command  => "/usr/lib/nagios/plugins/check_procs -c 1 -a '/usr/bin/varnishkafka -S /etc/varnishkafka/statsv.conf'",
        contact_group => 'admins,analytics',
        require       => Class['::varnishkafka'],
    }

    # Sets up Logster to read from the Varnishkafka instance stats JSON file
    # and report metrics to statsd.
    varnishkafka::monitor::statsd { 'statsv':
        graphite_metric_prefix => "varnishkafka.${::hostname}.statsv.${cache_cluster}"
        statsd_host_port       => hiera('statsd'),
    }
}
