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
    require_package('python-txstatsd', 'python-twisted-web', 'graphite-carbon')

    file { '/etc/init/txstatsd.conf':
        source => 'puppet:///modules/txstatsd/txstatsd.conf',
    }

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

    service { 'txstatsd':
        ensure    => running,
        subscribe => File['/etc/txstatsd/txstatsd.cfg'],
        require   => [
            File['/etc/init/txstatsd.conf'],
            Class[
                  'packages::python_txstatsd',
                  'packages::python_twisted_web',
                  'packages::graphite_carbon'
                  ],
            User['txstatsd'],
        ],
    }
}
