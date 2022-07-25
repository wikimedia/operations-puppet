class profile::cache::varnish::frontend::text {
    # for VCL compilation using libGeoIP
    class { '::geoip': }
    class { '::geoip::dev': }

    # Include ESI testing backend service in all text nodes
    class { '::esitest':
        numa_iface => $facts['interface_primary']
    }
}
