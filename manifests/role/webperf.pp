# == Class: role::webperf
#
# This role provisions a set of front-end monitoring tools that feed
# into StatsD.
#
class role::webperf {
    include ::webperf::statsv

    $eventlogging_host = 'eventlog1001.eqiad.wmnet'
    $statsd_host = 'statsd.eqiad.wmnet'

    # Aggregate client-side latency measurements collected via the
    # NavigationTiming MediaWiki extension and send them to Graphite.
    # See <https://www.mediawiki.org/wiki/Extension:NavigationTiming>
    class { '::webperf::navtiming':
        endpoint    => "tcp://${eventlogging_host}:8600",
        statsd_host => $statsd_host,
    }

    # Report VisualEditor performance measurements to Graphite.
    # See <https://meta.wikimedia.org/wiki/Schema:TimingData>
    class { '::webperf::ve':
        endpoint    => "tcp://${eventlogging_host}:8600",
        statsd_host => $statsd_host,
    }

    # See <https://meta.wikimedia.org/wiki/Schema:DeprecatedUsage>
    class { '::webperf::deprecate':
        endpoint    => "tcp://${eventlogging_host}:8600",
        statsd_host => $statsd_host,
    }

    # Provisions a service which gather stats about static assets count
    # and size using a headless browser instance. Stats are forwarded to
    # Ganglia using gmetric.
    class { '::webperf::asset_check':
        statsd_host => $statsd_host,
    }
}
