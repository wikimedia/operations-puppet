class role::cache::kafka::eventlogging(
    $varnish_name = $::hostname,
    $varnish_svc_name = 'varnish',
) inherits role::cache::kafka
{
    # Set varnish.arg.q or varnish.arg.m according to Varnish version
    if (hiera('varnish_version4', false)) {
        $varnish_opts = { 'q' => 'ReqURL ~ "^/(beacon/)?event(\.gif)?\?"' }
    } else {
        $varnish_opts = { 'm' => 'RxURL:^/(beacon/)?event(\.gif)?\?' }
    }

    varnishkafka::instance { 'eventlogging':
        # FIXME - top-scope var without namespace, will break in puppet 2.8
        # lint:ignore:variable_scope
        brokers                     => $kafka_brokers,
        # lint:endignore
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
        conf_template               => $conf_template,
    }
}
