# == Define varnish::logging::backendtiming:
# Mtail program parsing Backend-Timing Apache header and
# making stats available to Prometheus.
#
# === Parameters
#
# === Examples
#
#  varnish::logging::backendtiming {
#  }
#
define varnish::logging::backendtiming(
) {
    include ::varnish::common

    mtail::program { 'varnishbackendtiming':
        source      => 'puppet:///modules/mtail/programs/varnishbackendtiming.mtail',
        destination => '/etc/varnishmtail-backend',
        notify      => Service['varnishmtail-backend'],
    }
}
