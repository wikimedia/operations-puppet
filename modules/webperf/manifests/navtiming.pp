# == Class: webperf::navtiming
#
# Captures NavigationTiming event and send them to StatsD / Graphite.
# See https://meta.wikimedia.org/wiki/Schema:NavigationTiming &
# http://www.mediawiki.org/wiki/Extension:NavigationTiming
#
# === Parameters
#
# [*endpoint*]
#   URI of EventLogging event publisher to subscribe to.
#   Example: 'tcp://eventlogging.corp.org:8600'.
#
# [*eventlogging_path*]
#   Path where the EventLogging python library is installed.
#   Example: '/srv/deployment/eventlogging'.
#
# [*statsd_host*]
#   Write stats to this StatsD instance. Default: '127.0.0.1'.
#
# [*statsd_port*]
#   Write stats to this StatsD instance. Default: 8125.
#
class webperf::navtiming(
    $endpoint,
    $eventlogging_path,
    $statsd_host = '127.0.0.1',
    $statsd_port = 8125,
) {
    include ::webperf

    require_package('python-yaml')

    file { '/srv/webperf/navtiming.py':
        source => 'puppet:///modules/webperf/navtiming.py',
        owner  => 'www-data',
        group  => 'www-data',
        mode   => '0755',
        notify => Service['navtiming'],
    }

    file { '/lib/systemd/system/navtiming.service':
        content => template('webperf/navtiming.systemd.erb'),
        notify  => Service['navtiming'],
    }

    service { 'navtiming':
        ensure   => running,
        provider => systemd,
    }
}
