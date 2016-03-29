class varnish::apt_preferences {
    if (hiera('varnish_version4', false)) {
        # No pinning for Varnish 4
        apt::pin { 'varnish':
            ensure   => 'absent',
            pin      => '',
            priority => '',
        }
    } else {
        # Prefer v3 varnish packages
        apt::pin { 'varnish':
            package  => 'varnish varnish-dbg varnish-doc libvarnishapi1 libvarnishapi-dev',
            pin      => 'version 3.*',
            priority => 1002,
        }
    }
}
