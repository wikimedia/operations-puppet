# role class for diamond
class role::diamond {

    #these are notes just for initial rollout and testing:
    #tungsten: 10.64.0.18
    #(labs) athens graphite server: 10.68.17.73
    #Once https://gerrit.wikimedia.org/r/#/c/131449/ merges
    #start batching in groups of 10 to start, for now current statsd can't
    #accept multiple metrics

    case $::realm {
        'labs': {
            $host          = '10.64.37.13' # labmon1001
            # Prefix labs metrics with project name
            $path_prefix   = $::instanceproject
            $keep_logs_for = '0' # Current day only
            $service       = true
        }
        default: {
            $host          = '10.64.0.18'
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
            enabled     => 'true',
            host        => $host,
            port        => '8125',
        },
    }
}
