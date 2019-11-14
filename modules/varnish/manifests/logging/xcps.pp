# == Define: varnish::logging::xcps
#
# Mtail program parsing X-Connection-Properties header from the SSL terminators
# and making metrics available to Prometheus.
#
# === Parameters
#
# === Examples
#
#  varnish::logging::xcps {
#  }
#
define varnish::logging::xcps {
    include ::varnish::common

    mtail::program { 'varnishxcps':
        ensure => absent
    }
}
