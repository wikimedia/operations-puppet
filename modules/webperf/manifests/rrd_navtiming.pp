# == Class: webperf::rrd_navtiming
#
# Store a basic set of Navigation Timing metrics in RRD files.
# See https://meta.wikimedia.org/wiki/Schema:NavigationTiming &
# http://www.mediawiki.org/wiki/Extension:NavigationTiming
#
# === Parameters
#
# [*endpoint*]
#   URI of EventLogging event publisher to subscribe to.
#   For example, 'tcp://eventlogging.eqiad.wmnet:8600'.
#
class webperf::rrd_navtiming( $endpoint ) {
    include ::webperf

    file { '/srv/webperf/rrd-navtiming.py':
        source => 'puppet:///modules/webperf/rrd-navtiming.py',
        owner  => 'webperf',
        group  => 'webperf',
        mode   => '0755',
        notify => Service['rrd-navtiming'],
    }

    file { [ '/var/lib/rrd-navtiming', '/var/log/rrd-navtiming' ]:
        ensure => directory,
        owner  => 'webperf',
        group  => 'webperf',
        mode   => '0755',
        before => Service['rrd-navtiming'],
    }

    file { '/etc/init/rrd-navtiming.conf':
        content => template('webperf/rrd-navtiming.conf.erb'),
        notify  => Service['rrd-navtiming'],
    }

    service { 'rrd-navtiming':
        ensure   => running,
        provider => upstart,
    }
}
