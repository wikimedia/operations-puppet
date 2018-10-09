# == Define: varnish::logging::media
#
#  Accumulate browser cache hit ratio and total request volume statistics
#  for Media requests and report to StatsD. Expose metrics to prometheus.
#
# === Examples
#
#  varnish::logging::media {
#    statsd_server => 'statsd.eqiad.wmnet:8125
#  }
#
define varnish::logging::media {
    include ::varnish::common

    mtail::program { 'varnishmedia':
        source => 'puppet:///modules/mtail/programs/varnishmedia.mtail',
        notify => Service['varnishmtail'],
    }
}
