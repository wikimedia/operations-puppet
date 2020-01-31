class profile::cache::varnish::frontend::text {
    # for VCL compilation using libGeoIP
    class { '::geoip': }
    class { '::geoip::dev': }

    # ResourceLoader browser cache hit rate and request volume stats.
    ::varnish::logging::rls { 'rls':
    }

    # Temporary kludge to keep an eye on T243634
    if $::site == 'ulsfo' {
        prometheus::node_file_count {'track vcache fds':
            paths   => [ '/proc/$(pgrep -u vcache)/fd' ],
            outfile => '/var/lib/prometheus/node.d/vcache_fds.prom'
        }
    }
}
