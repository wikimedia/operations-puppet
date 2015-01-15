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

    if os_version('debian >= jessie') {
        $init_provider = 'systemd';
        $init_file = '/etc/systemd/system/txstatsd.service';
        file { $init_file:
            source => 'puppet:///modules/txstatsd/txstatsd.service'
        }
    }
    else {
        $init_provider = 'upstart';
        $init_file = '/etc/init/txstatsd.conf';
        file { $init_file:
            source => 'puppet:///modules/txstatsd/txstatsd.conf',
        }
    }

    service { 'txstatsd':
        ensure    => running,
        enable    => true,
        provider  => $init_provider,
        subscribe => File['/etc/txstatsd/txstatsd.cfg'],
        require   => [
            File[$init_file],
            Class[
                  'packages::python_txstatsd',
                  'packages::python_twisted_web',
                  'packages::graphite_carbon'
                  ],
            User['txstatsd'],
        ],
    }
}
