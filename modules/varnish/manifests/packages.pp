class varnish::packages($version='installed') {
    package { [
        'varnish',
        'varnish-dbg',
        'libvarnishapi1',
        ]:
        ensure  => $version,
    }

    # Install VMODs on Varnish 4 instances
    package { [
        'varnish-modules',
        'libvmod-netmapper',
        'libvmod-tbf',
        'libvmod-vslp',
        ]:
        ensure  => 'installed',
    }
}
