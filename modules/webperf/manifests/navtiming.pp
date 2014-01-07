# == Class: webperf::navtiming
#
# Captures NavigationTiming event and send them to StatsD / Graphite.
# See https://meta.wikimedia.org/wiki/Schema:NavigationTiming &
# http://www.mediawiki.org/wiki/Extension:NavigationTiming
#
class webperf::navtiming(
    $endpoint    = 'tcp://vanadium.eqiad.wmnet:8600',
    $statsd_host = '127.0.0.1',
    $statsd_port = 8125,
) {
    file { '/srv/webperf/navtiming.py':
        source => 'puppet:///modules/webperf/navtiming.py',
        owner  => 'www-data',
        group  => 'www-data',
        mode   => '0755',
        notify => Service['navtiming'],
    }

    file { '/usr/local/share/statsd/mediansOnlyFilter.js':
        content => 'exports.filter = function ( m ) { return /median$/.test( m.name ) && m; };',
        before  => Service['statsd'],
    }

    file { '/etc/init/navtiming.conf':
        content => template('webperf/navtiming.conf.erb'),
        notify  => Service['navtiming'],
    }

    service { 'navtiming':
        ensure   => running,
        provider => upstart,
    }

    class { '::statsd':
        settings => {
            flushInterval    => 5 * 60 * 1000,  # 5 min.
            backends         => [ 'ganglia' ],
            gangliaFilters   => [ '/usr/local/share/statsd/mediansOnlyFilter.js' ],
            address          => $statsd_host,
            percentThreshold => [ 95 ],
            # Show frequency distribution of client-side latency times.
            # See <http://tinyurl.com/statsd-histograms>.
            histogram        => [
                {
                    metric => 'browser',
                    bins   => [ 100, 500, 1000, 2000, 5000, 'inf' ],
                },
            ],
            gangliaHost      => $::ganglia::mcast_address,
            gangliaMulticast => true,
            gangliaSpoofHost => 'client-side',
        },
    }
}
