class role::cache::logging::eventlistener( $instance_name = '' ) {
    $event_listener = $::realm ? {
        # default to eventlog1001
        'production' => hiera('eventlogging_host', '10.64.32.167'),
        # default to deployment-eventlogging03
        'labs'       => hiera('eventlogging_host', '10.68.18.111'),
    }

    varnish::logging { 'eventlogging' :
        listener_address => $event_listener,
        port             => '8422',
        instance_name    => $instance_name,
        cli_args         => '-m RxURL:^/(beacon/)?event(\.gif)?\?. -D',
        log_fmt          => '%q\t%l\t%n\t%t\t%h\t"%{User-agent}i"',
        monitor          => false,
        # This is being replaced by varnishkafka.
        # This class will be removed.
        ensure           => 'absent',
    }
}
