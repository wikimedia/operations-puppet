# == Class: role::statsite
#
# statsite is a network daemon that listens on a socket for metric data (like
# timers and counters) and writes aggregates to a metric storage backend like
# Graphite or Ganglia. See <https://github.com/armon/statsite>.
#
class profile::statsite {

    class { '::statsite': }
    statsite::instance { '8125': }

    diamond::collector { 'UDPCollector': }
}
