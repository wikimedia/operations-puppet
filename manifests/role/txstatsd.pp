# == Class: role::txstatsd
#
# txStatsD is a network daemon that listens on a socket for metric data (like
# timers and counters) and writes aggregates to a metric storage backend like
# Graphite or Ganglia. See <https://github.com/sidnei/txstatsd>.
#
class role::txstatsd {
    class { '::txstatsd':
        settings => {
            statsd => {
                'carbon-cache-host' => 'localhost',
                'carbon-cache-port' => 2003,
                'listen-port'       => 8125,
                'listen-tcp-port'   => 8125,
                'statsd-compliance' => 0,
            },
        },
    }
}
