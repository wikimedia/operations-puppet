# == Class: profile::statsite
#
# statsite is a network daemon that listens on a socket for metric data (like
# timers and counters) and writes aggregates to a metric storage backend like
# Graphite or Ganglia. See <https://github.com/armon/statsite>.
#
class profile::statsite (
  Optional[Stdlib::Host]   $graphite_host = lookup('graphite_host'),
  Wmflib::Ensure           $ensure = lookup('profile::statsite::ensure', { 'default_value' => 'present' }),
) {
    system::role { 'statsite':
        description => 'statsite server'
    }

    if $ensure == 'present' and $graphite_host == undef {
        fail('$graphite_host required, but it is set to undef')
    }

    class { '::statsite':
        ensure => $ensure,
    }
    statsite::instance { '8125':
        ensure        => $ensure,
        graphite_host => $graphite_host,
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
        port    => 8125,
    }
}
