# == Class: webperf::ve
#
# Captures VisualEditor timing data and sends it to StatsD.
#
# === Parameters
#
# [*endpoint*]
#   URI of EventLogging event publisher to subscribe to.
#   Example: 'tcp://eventlogging.corp.org:8600'.
#
# [*statsd_host*]
#   Write stats to this StatsD instance. Default: '127.0.0.1'.
#
# [*statsd_port*]
#   Write stats to this StatsD instance. Default: 8125.
#
class webperf::ve(
    $endpoint,
    $statsd_host = '127.0.0.1',
    $statsd_port = 8125,
) {
    include ::webperf

    file { '/srv/webperf/ve.py':
        source => 'puppet:///modules/webperf/ve.py',
        owner  => 'www-data',
        group  => 'www-data',
        mode   => '0755',
        notify => Service['ve'],
    }

    file { '/etc/init/ve.conf':
        content => template('webperf/ve.conf.erb'),
        notify  => Service['ve'],
    }

    service { 've':
        ensure   => running,
        provider => upstart,
    }
}
