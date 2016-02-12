# role class for diamond
class role::diamond {

    case $::realm {
        'labs': {
            $host          = '10.64.37.13' # labmon1001
            # Prefix labs metrics with project name
            $path_prefix   = $::labsproject
            $keep_logs_for = '0' # Current day only
            $service       = true
        }
        default: {
            $host          = '10.64.32.155' # graphite1001
            $path_prefix   = 'servers'
            $keep_logs_for = '5'
            $service       = true
        }
    }

    class { '::diamond':
        path_prefix   => $path_prefix,
        keep_logs_for => $keep_logs_for,
        service       => $service,
        settings      => {
            # lint:ignore:quoted_booleans
            # Diamond needs its bools in string-literals.
            enabled => 'true',
            # lint:endignore
            host    => $host,
            port    => '8125',
            batch   => '20',
        },
    }
}
