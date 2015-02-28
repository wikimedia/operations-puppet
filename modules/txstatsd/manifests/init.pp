# == Class: txstatsd
#
# txStatsD is a network daemon that listens on a socket for metric data (like
# timers and counters) and writes aggregates to a metric storage backend like
# Graphite or Ganglia. See <https://github.com/sidnei/txstatsd>.
#
# === Parameters
#
# [*settings*]
#   Hash of hashes. Each top-level hash correspond to a config section.
#   See <https://github.com/sidnei/txstatsd/blob/master/txstatsd.conf-example>.
#
# === Examples
#
#  class { 'txstatsd':
#    settings => {
#      statsd => {
#        'carbon-cache-host' => localhost,
#        'carbon-cache-port' => 2003,
#        'listen-tcp-port'   => 8125,
#      },
#    },
#  }
#
class txstatsd($settings) {
    package { 'python-txstatsd': }

    file { '/etc/txstatsd':
        ensure => directory,
        owner  => 'root',
        group  => 'root',
        mode   => '0555',
    }

    file { '/etc/txstatsd/txstatsd.cfg':
        owner  => 'root',
        group  => 'root',
        mode   => '0444',
        content => template('txstatsd/txstatsd.cfg.erb'),
    }

    group { 'txstatsd':
        ensure => present,
    }

    user { 'txstatsd':
        ensure     => present,
        gid        => 'txstatsd',
        shell      => '/bin/false',
        home       => '/nonexistent',
        system     => true,
        managehome => false,
    }

    base::service_unit { 'txstatsd':
        systemd => true,
        upstart => true,
        service_params => {
            enable    => true,
            subscribe => File['/etc/txstatsd/txstatsd.cfg'],
            require   => [
                Package['python-txstatsd'],
                User['txstatsd'],
            ],
        }
    }
}
