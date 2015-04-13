class role::cache::logging {
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
