# standard class for diamond
class standard::diamond {

    case $::realm {
        'labs': {
            $host          = '10.64.37.13' # labmon1001
            $port          = '2003'
            # Prefix labs metrics with project name
            $path_prefix   = $::labsproject
            $keep_logs_for = '0' # Current day only
            $service       = true
            $handler       = 'diamond.handler.graphite.GraphiteHandler'
        }
        default: {
            $host          = '10.64.32.155' # graphite1001
            $port          = '2003'
            $path_prefix   = 'servers'
            $keep_logs_for = '5'
            $service       = true
            $handler       = 'diamond.handler.graphite.GraphiteHandler'
        }
    }

    # Enabled by default on prod, disabled on almost all labs instances except specific ones
    # FIXME: Get rid of this once we fix https://phabricator.wikimedia.org/T127957
    $enabled = hiera('diamond_enabled', true)

    class { '::diamond':
        handler       => $handler,
        path_prefix   => $path_prefix,
        keep_logs_for => $keep_logs_for,
        service       => $service,
        settings      => {
            # lint:ignore:only_variable_string
            # Diamond needs its bools in string-literals.
            enabled => "${enabled}",
            # lint:endignore
            host    => $host,
            port    => $port,
            batch   => '20',
        },
    }
}
