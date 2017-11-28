# == Class varnish::logging
#
# This class sets up analytics/logging needed by cache servers
#
# === Parameters
#
# [*cache_cluster*]
#   The cache cluster we're part of.
#
# [*statsd_host*]
#   The statsd host to send stats to.
#
# [*forward_syslog*]
#   Host and port to forward syslog events to. Disable forwarding by passing an
#   empty string (default).
#
class varnish::logging(
    $cache_cluster,
    $statsd_host,
    $forward_syslog='',
){
    rsyslog::conf { 'varnish':
        content  => template('varnish/rsyslog.conf.erb'),
        priority => 80,
    }

    # Client connection stats from the 'X-Connection-Properties'
    # header set by the SSL terminators.
    ::varnish::logging::xcps { 'xcps':
        statsd_server => $statsd_host,
    }

    ::varnish::logging::statsd { 'default':
        statsd_server => $statsd_host,
        key_prefix    => "varnish.${::site}.backends",
    }

    # Parse varnishlogs for request statistics and send to statsd.
    varnish::logging::reqstats { 'frontend':
        key_prefix => "varnish.${::site}.${cache_cluster}.frontend.request",
        statsd     => $statsd_host,
    }

    ::varnish::logging::xcache { 'xcache':
        key_prefix    => "varnish.${::site}.${cache_cluster}.xcache",
        statsd_server => $statsd_host,
    }
}
