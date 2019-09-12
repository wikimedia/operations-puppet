# == Class: profile::statsite
#
# statsite is a network daemon that listens on a socket for metric data (like
# timers and counters) and writes aggregates to a metric storage backend like
# Graphite or Ganglia. See <https://github.com/armon/statsite>.
#
class profile::statsite (
  $ensure = lookup('profile::statsite::ensure', { 'default_value' => 'present' }),
) {
    system::role { 'statsite':
        description => 'statsite server'
    }

    class { '::statsite':
        ensure => $ensure,
    }
    statsite::instance { '8125':
        ensure => $ensure,
    }

    ferm::service { 'statsite':
        ensure  => $ensure,
        proto   => 'udp',
        notrack => true,
        port    => '8125',
    }

    ferm::client { 'statsite':
        ensure  => $ensure,
        proto   => 'udp',
        notrack => true,
        port    => '8125',
    }
}
