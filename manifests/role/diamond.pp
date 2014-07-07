# role class for diamond
class role::diamond {

    # Labs projects in which to enable diamond. This is to reduce
    # the load on the collector instance, which could not handle
    # all the metrics from all the projects.
    $labs_enabled_projects = ['tools', 'deployment-prep', 'graphite']
    #these are notes just for initial rollout and testing:
    #tungsten: 10.64.0.18
    #(labs) athens graphite server: 10.68.17.73
    #Once https://gerrit.wikimedia.org/r/#/c/131449/ merges
    #start batching in groups of 10 to start, for now current statsd can't
    #accept multiple metrics

    # Point to diamond-collector on labs and tungsten on prod
    case $::realm {
        'labs': {
            $host = '10.68.17.169'
            # Prefix labs metrics with project name
            $path_prefix = $::instanceproject
            $keep_logs_for = '0' # Keep only current day's logs, saves space
            # Enable only in specific projects
            if member($labs_enabled_projects, $::instanceproject) {
                $ensure = present
            } else {
                $ensure = absent
            }
        }
        default: {
            $host = '10.64.0.18'
            $path_prefix = 'servers'
            $keep_logs_for = '5'
            $ensure = present
        }
    }

    class { '::diamond':
        path_prefix   => $path_prefix,
        keep_logs_for => $keep_logs_for,
        ensure        => present,
        settings        => {
            host        => $host,
            port        => '8125',
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
