# == Class role::cache::kafka::statsv
# Sets up a varnishkafka logging endpoint for collecting
# application level metrics. We are calling this system
# statsv, as it is similar to statsd, but uses varnish
# as its logging endpoint.
#
# == Parameters
# $varnish_name - the name of the varnish instance to read shared logs from.  Default $::hostname
# $varnish_svc_name - the name of the varnish init service to read shared logs from.  Default 'varnish'
#
class role::cache::kafka::statsv(
    $varnish_name = $::hostname,
    $varnish_svc_name = 'varnish',
) inherits role::cache::kafka
{
    $format  = "%{fake_tag0@hostname?${::fqdn}}x %{%FT%T@dt}t %{X-Client-IP@ip}o %{@uri_path}U %{@uri_query}q %{User-Agent@user_agent}i"

    # Set varnish.arg.q or varnish.arg.m according to Varnish version
    $varnish_opts = { 'q' => 'ReqURL ~ "^/beacon/statsv\?"' }
    $conf_template = 'varnishkafka/varnishkafka_v4.conf.erb'

    varnishkafka::instance { 'statsv':
        # FIXME - top-scope var without namespace, will break in puppet 2.8
        # lint:ignore:variable_scope
        brokers                     => $kafka_brokers,
        # lint:endignore
        format                      => $format,
        format_type                 => 'json',
        topic                       => 'statsv',
        varnish_name                => $varnish_name,
        varnish_svc_name            => $varnish_svc_name,
        varnish_opts                => $varnish_opts,
        # -1 means all brokers in the ISR must ACK this request.
        topic_request_required_acks => '-1',
        conf_template               => $conf_template,
    }

    include ::standard

    $cache_type = hiera('cache::cluster')
    $graphite_metric_prefix = "varnishkafka.${::hostname}.statsv.${cache_type}"

    # Sets up Logster to read from the Varnishkafka instance stats JSON file
    # and report metrics to statsd.
    varnishkafka::monitor::statsd { 'statsv':
        graphite_metric_prefix => $graphite_metric_prefix,
        statsd_host_port       => hiera('statsd'),
    }
}
