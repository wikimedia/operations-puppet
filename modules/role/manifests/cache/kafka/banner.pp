class role::cache::kafka::banner(
    $varnish_name = $::hostname,
    $varnish_svc_name = 'varnish',
) inherits role::cache::kafka
{
    varnishkafka::instance { 'banner':
        brokers           => $kafka_brokers,
        # Note that this format uses literal tab characters.
        format            => '%q	%l	%n	%{%FT%T}t	%h	"%{User-agent}i"',
        format_type       => 'string',
        topic             => 'banner',
        varnish_name      => $varnish_name,
        varnish_svc_name  => $varnish_svc_name,
        varnish_opts      => { 'm' => 'RxURL:^/beacon/banner\?.' },
        topic_request_required_acks  => '-1',
    }
}
