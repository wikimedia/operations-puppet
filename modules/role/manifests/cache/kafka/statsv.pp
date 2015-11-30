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

    varnishkafka::instance { 'statsv':
        brokers           => $kafka_brokers,
        format            => $format,
        format_type       => 'json',
        topic             => 'statsv',
        varnish_name      => $varnish_name,
        varnish_svc_name  => $varnish_svc_name,
        varnish_opts      => { 'm' => 'RxURL:^/beacon/statsv\?', },
        # -1 means all brokers in the ISR must ACK this request.
        topic_request_required_acks  => '-1',
    }

    if $::standard::has_ganglia {
        varnishkafka::monitor { 'statsv': }
    }
}
