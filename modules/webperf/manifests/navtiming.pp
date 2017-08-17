# == Class: webperf::navtiming
#
# Captures NavigationTiming events from Kafka and send them to StatsD / Graphite.
# See https://meta.wikimedia.org/wiki/Schema:NavigationTiming &
# http://www.mediawiki.org/wiki/Extension:NavigationTiming
#
# === Parameters
#
# [*kafka_brokers*]
#   string of comma separated Kafka bootstrap brokers
#
# [*statsd_host*]
#   Write stats to this StatsD instance. Default: '127.0.0.1'.
#
# [*statsd_port*]
#   Write stats to this StatsD instance. Default: 8125.
#
class webperf::navtiming(
    $kafka_brokers,
    $statsd_host   = '127.0.0.1',
    $statsd_port   = 8125,
) {
    include ::webperf

    require_package('python-kafka')
    require_package('python-yaml')

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
