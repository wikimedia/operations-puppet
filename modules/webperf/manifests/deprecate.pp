# == Class: webperf::deprecate
#
# Captures mw.log.deprecate data and sends it to StatsD.
#
# See https://meta.wikimedia.org/wiki/Schema:DeprecatedUsage.
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
class webperf::deprecate(
    $endpoint,
    $statsd_host = '127.0.0.1',
    $statsd_port = 8125,
) {
    include ::webperf

    file { '/srv/webperf/deprecate.py':
        source => 'puppet:///modules/webperf/deprecate.py',
        owner  => 'www-data',
        group  => 'www-data',
        mode   => '0755',
        notify => Service['statsd-mw-js-deprecate'],
    }

    file { '/lib/systemd/system/statsd-mw-js-deprecate.service':
        content => template('webperf/deprecate.systemd.erb'),
        notify  => Service['statsd-mw-js-deprecate'],
    }

    service { 'statsd-mw-js-deprecate':
        ensure   => running,
        provider => systemd,
    }
}
