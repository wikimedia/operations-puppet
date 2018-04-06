# == Define varnish::logging::xcache:
# Mtail program parsing X-Cache header and
# making hit-related stats available to Prometheus.
#
# === Parameters
#
# === Examples
#
#  varnish::logging::xcache {
#  }
#
define varnish::logging::xcache(
) {
    include ::varnish::common

    mtail::program { 'varnishxcache':
        source => 'puppet:///modules/mtail/programs/varnishxcache.mtail',
        notify => Service['varnishmtail'],
    }
}
