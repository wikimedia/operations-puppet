# @summary profile to configure varnish frontend text nodes
# @param esitest_ensure ensureable parameter for esitest
class profile::cache::varnish::frontend::text (
    Wmflib::Ensure $esitest_ensure = lookup('profile::cache::varnish::frontend::text::esitest_ensure'),
) {
    # for VCL compilation using libGeoIP
    class { 'geoip': }
    class { 'geoip::dev': }

    # Include ESI testing backend service in all text nodes
    class { 'esitest':
        ensure     => $esitest_ensure,
        numa_iface => $facts['interface_primary'],
    }
}
