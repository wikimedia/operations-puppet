class varnish::apt_preferences {
    if (hiera('varnish_version4', false)) {
        # No pinning for Varnish 4
        apt::pin { 'varnish':
            ensure   => 'absent',
            pin      => '',
            priority => '',
        }

        apt::pin { 'varnishkafka':
            ensure   => 'absent',
            pin      => '',
            priority => '',
        }
    } else {
        # Prefer v3 varnish packages
        apt::pin { 'varnish':
            package  => 'varnish varnish-dbg libvarnishapi1 libvarnishapi-dev',
            pin      => 'version 3.*',
            priority => 1002,
        }

        # Prefer varnishkafka 1.0.7, compatible with varnish 3
        apt::pin { 'varnishkafka':
            package  => 'varnishkafka*',
            pin      => 'version 1.0.7*',
            priority => 1002,
        }
    }
}
