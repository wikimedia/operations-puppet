# == Class: webperf::ve
#
# Captures VisualEditor timing data and sends it to StatsD.
# See <https://meta.wikimedia.org/wiki/Schema:Edit>.
#
# === Parameters
#
# [*kafka_brokers*]
#   String of comma separated Kafka bootstrap brokers.
#
# [*statsd_host*]
#   Write stats to this StatsD instance. Default: '127.0.0.1'.
#
# [*statsd_port*]
#   Write stats to this StatsD instance. Default: 8125.
#
class webperf::ve(
    $kafka_brokers,
    $statsd_host = '127.0.0.1',
    $statsd_port = 8125,
) {
    include ::webperf

    require_package('python-kafka')
    require_package('python-yaml')

    file { '/srv/webperf/ve.py':
        source => 'puppet:///modules/webperf/ve.py',
        owner  => 'www-data',
        group  => 'www-data',
        mode   => '0755',
        notify => Service['ve'],
    }

    file { '/lib/systemd/system/ve.service':
        # uses $statsd_host, $statsd_port, $kafka_brokers
        content => template('webperf/ve.systemd.erb'),
        notify  => Service['ve'],
    }

    service { 've':
        ensure   => running,
        provider => systemd,
    }
}
