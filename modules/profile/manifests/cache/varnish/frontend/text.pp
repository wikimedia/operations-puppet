class profile::cache::varnish::frontend::text {
    # for VCL compilation using libGeoIP
    class { '::geoip': }
    class { '::geoip::dev': }

    # ResourceLoader browser cache hit rate and request volume stats.
    ::varnish::logging::rls { 'rls':
    }
}
