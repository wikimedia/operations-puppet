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
    if (hiera('varnish_version4', false)) {
        $varnish_opts = { 'q' => 'ReqURL ~ "^/beacon/statsv\?"' }
    } else {
        $varnish_opts = { 'm' => 'RxURL:^/beacon/statsv\?' }
    }

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
        if (hiera('varnish_version4', true)) {
            $conf_template = 'varnishkafka/varnishkafka_v4.conf.erb',
        }
    }

    if $::standard::has_ganglia {
        varnishkafka::monitor { 'statsv': }
    }
}
