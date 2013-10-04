# == Class: role::statsd
#
# StatsD is a simple network daemon that listens to application metrics
# and aggregates them for easy plotting and analysis in Graphite or
# Ganglia.
#
class role::statsd {
    class { '::statsd':
        settings => {
            backends     => [ 'graphite' ],
            graphiteHost => 'professor.pmtpa.wmnet',
        },
    }
}
