# == Define: varnish::logging::rls
#
#  Accumulate browser cache hit ratio and total request volume statistics for
#  ResourceLoader requests (/w/load.php) and expose metrics to prometheus.
#
define varnish::logging::rls {
    include ::varnish::common

    mtail::program { 'varnishrls':
        source => 'puppet:///modules/mtail/programs/varnishrls.mtail',
        notify => Service['varnishmtail@default'],
    }
}
