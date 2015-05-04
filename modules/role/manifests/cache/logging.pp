class role::cache::logging(
    $udp2log = false,
    $eventlogging = false,
    $eventlogging_instance_name = '',
) {
    if $udp2log and $eventlistener {
        $monitor_instances = 3
    }
    elsif $udp2log {
        $monitor_instances = 2
    }
    elsif $eventlistener {
        $monitor_instances = 1
    }
    else {
        error('udp2log and/or eventlogging must be true for role::cache::logging')
    }

    if $udp2log {
        if $::realm == 'production' {
            $webrequest_multicast_relay_host = '208.80.154.73' # gadoinium

            $cliargs = '-m RxRequest:^(?!PURGE$) -D'
            varnish::logging { 'multicast_relay':
                    listener_address => $webrequest_multicast_relay_host,
                    port             => '8419',
                    cli_args         => $cliargs,
            }

            varnish::logging { 'erbium':
                    listener_address => '10.64.32.135',
                    port             => '8419',
                    cli_args         => $cliargs,
            }
        }
    }

    if $eventlistener {
        $event_listener = $::realm ? {
            'production' => '10.64.32.167',  # eventlog1001
            'labs'       => '10.68.16.52',   # deployment-eventlogging02
        }

        varnish::logging { 'eventlogging' :
            listener_address => $event_listener,
            port             => '8422',
            instance_name    => $eventlogging_instance_name,
            cli_args         => '-m RxURL:^/(beacon/)?event\.gif\?. -D',
            log_fmt          => '%q\t%l\t%n\t%t\t%h\t"%{User-agent}i"',
        }
    }

    class { '::varnish::logging::monitor':
        num_instances => $monitor_instances
    }
}
