# == Class: webperf::navtiming
#
# Captures NavigationTiming event and send them to StatsD / Graphite.
# See https://meta.wikimedia.org/wiki/Schema:NavigationTiming &
# http://www.mediawiki.org/wiki/Extension:NavigationTiming
#
# === Parameters
#
# [*statsd_host*]
#   Write stats to this StatsD instance. Default: '127.0.0.1'.
#
# [*statsd_port*]
#   Write stats to this StatsD instance. Default: 8125.
#
class webperf::navtiming(
    $statsd_host = '127.0.0.1',
    $statsd_port = 8125,
) {
    include ::webperf

    require_package('python-yaml')

    $kafka_config  = kafka_config('analytics')
    $kafka_brokers = $kafka_config['brokers']['string']

    file { '/srv/webperf/navtiming.py':
        source => 'puppet:///modules/webperf/navtiming.py',
        owner  => 'www-data',
        group  => 'www-data',
        mode   => '0755',
        notify => Service['navtiming'],
    }

    file { '/lib/systemd/system/navtiming.service':
        # uses $statsd_host, $statsd_port, $kafka_brokers
        content => template('webperf/navtiming.systemd.erb'),
        notify  => Service['navtiming'],
    }

    service { 'navtiming':
        ensure   => running,
        provider => systemd,
    }
}
