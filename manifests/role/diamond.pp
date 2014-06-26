# role class for diamond
class role::diamond {

    #these are notes just for initial rollout and testing:
    #tungsten: 10.64.0.18
    #(labs) athens graphite server: 10.68.17.73
    #Once https://gerrit.wikimedia.org/r/#/c/131449/ merges
    #start batching in groups of 10 to start, for now current statsd can't
    #accept multiple metrics

    # Point to diamond-collector on labs and tungsten on prod
    case $::realm {
        'labs': { $host = '10.68.17.169' }
        default: { $host = '10.64.0.18' }
    }

    # Prefix labs metrics with project name
    case $::realm {
        'labs': { $path_prefix = $::instanceproject }
        default: { $path_prefix = 'system' }
    }

    class { '::diamond':
        settings        => {
            enabled     => 'true',
            host        => $host,
            port        => '8125',
            path_prefix => $path_prefix,
        },
    }

    #IPVS collector seems to be enabled by default on trusty
    #causes non LVS hosts to spam with sudo violations for
    #stats collection among other things.  Explicit disable
    #for now this needs to dealt with upstream.
    case $::operatingsystemrelease {
        '14.04': {
            diamond::collector { 'IPVS':
                settings => {
                    enabled => 'false',
                },
            }
        }
    }
}
