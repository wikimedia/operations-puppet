class role::cache::logging::eventlistener {
    $event_listener = $::realm ? {
        'production' => '10.64.32.167',  # eventlog1001
        'labs'       => '10.68.16.52',   # deployment-eventlogging02
    }

    varnish::logging { 'eventlogging' :
        listener_address => $event_listener,
        port             => '8422',
        instance_name    => '',
        cli_args         => '-m RxURL:^/event\.gif\?. -D',
        log_fmt          => '%q\t%l\t%n\t%t\t%h\t"%{User-agent}i"',
        monitor          => false,
    }
}
