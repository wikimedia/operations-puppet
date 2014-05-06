# == Class: diamond
#
# Diamond is a Python network daemon that collects system metrics and
# publishes them to a metric aggregator like Graphite or StatsD. Diamond
# ships with a suite of metric collectors for CPU, memory, network, disk,
# etc. Diamond also features an API for implementing custom collectors
# that gather metrics from almost any source.
#
# === Parameters
#
# [*handler*]
#   Import path and class name of diamond.handler.Handler subclass to
#   use as the metric sink. Set to 'diamond.handler.dastatsd.StatsHandler'
#   by default. To have Diamond write to Graphite instead, set this to
#   'diamond.handler.graphite.GraphiteHandler'.
#
#   See <https://github.com/BrightcoveOS/Diamond/wiki/Handlers>
#   for a full list of available metric handlers.
#
# [*settings*]
#   A hash of configuration options for the desired handler.
#   See <https://github.com/BrightcoveOS/Diamond/wiki/Handlers>
#   for a listing of configuration options.
#
# === Examples
#
# A Graphite configuration for Diamond:
#
#  class { '::diamond':
#    handler  => 'diamond.handler.graphite.GraphiteHandler',
#    settings => {
#      host => 'graphite.wikimedia.org',
#      port => 2003,
#    },
#  }
#
class diamond(
    $handler  = 'diamond.handler.dastatsd.StatsHandler',
    $settings = { host => 'localhost',
                  port => '8125',
    },
) {
    package { ['python-diamond', 'python-configobj']:
        ensure => present,
    }

    file { '/etc/diamond/diamond.conf':
        content => template('diamond/diamond.conf.erb'),
        require => File['/etc/diamond/collectors', '/etc/diamond/handlers'],
    }

    file { [ '/etc/diamond/collectors', '/etc/diamond/handlers' ]:
        ensure  => directory,
        owner   => 'root',
        group   => 'root',
        mode    => '0644',
        recurse => true,
        purge   => true,
        force   => true,
        require => Package['python-diamond'],
    }

    # Truncate the import path, leaving only the class name.
    $handler_class = regsubst($handler, '.*\.', '')
    file { "/etc/diamond/handlers/${handler_class}.conf":
        content => template('diamond/handler.conf.erb'),
    }

    service { 'diamond':
        ensure     => running,
        enable     => true,
        hasrestart => true,
        hasstatus  => true,
        require    => Package['python-diamond'],
        subscribe  => File['/etc/diamond/diamond.conf'],
    }
}
