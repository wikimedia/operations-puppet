# == Class: statsd
#
# StatsD is a simple network daemon that listens to application metrics
# and aggregates them for easy plotting and analysis in Graphite or
# Ganglia. The simplicity of StatsD's UDP-based wire protocol and its
# ability to keep track of whatever data is sent to it make it a simple
# and effective means of instrumenting software.
#
# === Parameters
#
# [*port*]
#   Port to listen for messages on over UDP (default: 8125).
#
# [*settings*]
#   A hash of additional configuration options. For a full listing,
#   see <https://github.com/etsy/statsd/blob/master/exampleConfig.js>.
#
# === Example
#
#  class { 'statsd':
#      port     => 9000,
#      settings => {
#          backends     => [ 'graphite' ],
#          graphiteHost => '',
#          graphitePort => 2004,
#      },
#  }
#
class statsd(
    $port          = 8125,
    $settings      = {},
) {
    package { 'statsd':
        ensure => present,
    }

    file { '/etc/statsd/localConfig.js':
        content => template('statsd/localConfig.js.erb'),
        require => Package['statsd'],
        notify  => Service['statsd'],
    }

    file { '/usr/local/share/statsd':
        ensure => directory,
    }

    service { 'statsd':
        ensure   => running,
    }
}
