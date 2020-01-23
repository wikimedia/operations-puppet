class varnish::packages($version='installed') {
    package { [
        'varnish',
        'varnish-dbg',
        'libvarnishapi1',
        ]:
        ensure  => $version,
    }

    # Install VMODs
    package { [
        'varnish-modules',
        'libvmod-netmapper',
        'libvmod-re2',
        'libvmod-tbf',
        ]:
        ensure  => 'installed',
    }
}
