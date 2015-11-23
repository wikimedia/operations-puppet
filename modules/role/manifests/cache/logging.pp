# NOTE: This class is no longer being used and may be removed
# as soon as varnishncsa instances are ensure absent on cache hosts

class role::cache::logging {
    if $::realm == 'production' {
        $webrequest_multicast_relay_host = '208.80.154.73' # gadoinium

        $cliargs = '-m RxRequest:^(?!PURGE$) -D'
        varnish::logging { 'multicast_relay':
                listener_address => $webrequest_multicast_relay_host,
                port             => '8419',
                cli_args         => $cliargs,
                ensure           => 'absent',
        }

        varnish::logging { 'erbium':
                ensure           => 'absent',
                listener_address => '10.64.32.135',
                port             => '8419',
                cli_args         => $cliargs,
        }
    }
}
