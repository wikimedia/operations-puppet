# role class for diamond
class role::diamond {

    case $::realm {
        'labs': {
            $host          = '10.64.37.13' # labmon1001
            $port          = '2003'
            # Prefix labs metrics with project name
            $path_prefix   = $::labsproject
            $keep_logs_for = '0' # Current day only
            $service       = true
            $handler       = 'diamond.handler.graphite.GraphiteHandler',
        }
        default: {
            $host          = '10.64.32.155' # graphite1001
            $port          = '8125',
            $path_prefix   = 'servers'
            $keep_logs_for = '5'
            $service       = true
            $handler       = 'diamond.handler.stats_d.StatsdHandler',
        }
    }

    class { '::diamond':
        handler       => $handler,
        path_prefix   => $path_prefix,
        keep_logs_for => $keep_logs_for,
        service       => $service,
        settings      => {
            # lint:ignore:quoted_booleans
            # Diamond needs its bools in string-literals.
            enabled => 'true',
            # lint:endignore
            host    => $host,
            port    => $port,
            batch   => '20',
        },
    }
}
