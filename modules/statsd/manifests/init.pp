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
# [*graphite_host*]
#   Hostname or IP of Graphite server (default: localhost).
#
# [*graphite_port*]
#   Port of Graphite server (default: 2003).
#
# [*settings*]
#   A hash of additional configuration options. For a full listing,
#   see <https://github.com/etsy/statsd/blob/master/exampleConfig.js>.
#
# === Example
#
#  class { 'statsd':
#      graphite_host = 'professor.pmtpa.wmnet',
#      graphite_port = 2004,
#  }
#
class statsd(
    $port          = 8125,
    $graphite_host = 'localhost',
    $graphite_port = 2003,
    $settings      = {},
) {
    $config = ordered_json($settings, {
        port         => $port,
        graphiteHost => $graphite_host,
        graphitePort => $graphite_port,
    })

    package { 'statsd':
        ensure => present,
    }

    file { '/etc/statsd/localConfig.js':
        content => template('statsd/localConfig.js.erb'),
        require => Package['statsd'],
        notify  => Service['statsd'],
    }

    file { '/usr/share/statsd/backends/gmetric.js':
        source  => 'puppet:///modules/statsd/backends/gmetric.js',
        require => Package['statsd'],
    }

    file { '/usr/share/statsd/backends/ganglia.js':
        source  => 'puppet:///modules/statsd/backends/ganglia.js',
        require => Package['statsd'],
    }

    service { 'statsd':
        ensure   => running,
        provider => upstart,
    }
}
