# == Class: pystatsd
#
# Provisions pystatsd, an implementation of StatsD in Python. pystatsd
# listens on a network interface for metric data. It computes roll-ups
# and flushes them to Graphite or Ganglia.
#
# === Parameters
#
# [*settings*]
#   A hash of configuration options. For a full listing of options,
#   see <http://tinyurl.com/pystatsd-args>.
#
# === Example
#
#  class { 'pystatsd':
#      settings => {
#          transport     => 'graphite',
#          graphite_host => 'professor.pmtpa.wmnet',
#          graphite_port => 2003,
#      },
#  }
#
class pystatsd(
    $settings = {},
) {
    package { 'python-ss-statsd':
        ensure => present,
        before => File['/etc/init/pystatsd.conf'],
    }

    file { '/etc/init/pystatsd.conf':
        content => template('pystatsd/pystatsd.conf.erb'),
        before  => Service['pystatsd'],
    }

    service { 'pystatsd':
        ensure    => running,
        provider  => upstart,
    }
}
