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
                'carbon-cache-host'          => 'localhost',
                'carbon-cache-port'          => 2004,
                'listen-port'                => 8125,
                'statsd-compliance'          => 0,
                'prefix'                     => '',
                'max-queue-size'             => 1000 * 1000,
                'max-datapoints-per-message' => 10 * 1000,
            },
        },
    }
}
