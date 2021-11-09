class profile::cache::varnish::frontend::text {
    # for VCL compilation using libGeoIP
    class { '::geoip': }
    class { '::geoip::dev': }
}
