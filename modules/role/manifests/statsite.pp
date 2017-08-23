# == Class: role::statsite
#
# statsite is a network daemon that listens on a socket for metric data (like
# timers and counters) and writes aggregates to a metric storage backend like
# Graphite or Ganglia. See <https://github.com/armon/statsite>.
#
class role::statsite {
    system::role { 'statsite':
        description => 'statsite server'
    }

    class { '::statsite': }
    statsite::instance { '8125': }

    diamond::collector { 'UDPCollector': }

    ferm::service { 'statsite':
        proto   => 'udp',
        notrack => true,
        port    => '8125',
    }

    ferm::client { 'statsite':
        proto   => 'udp',
        notrack => true,
        port    => '8125',
    }
}
