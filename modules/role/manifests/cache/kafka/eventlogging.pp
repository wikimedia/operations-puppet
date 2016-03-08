class role::cache::kafka::eventlogging(
    $varnish_name = $::hostname,
    $varnish_svc_name = 'varnish',
) inherits role::cache::kafka
{
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
        varnish_opts                => {
            'm' => 'RxURL:^/(beacon/)?event(\.gif)?\?',
        },
        topic_request_required_acks => '1',
    }
}
