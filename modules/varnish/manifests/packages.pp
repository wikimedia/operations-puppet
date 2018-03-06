class varnish::packages($version='installed', $varnish_version=5) {
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
        'libvmod-tbf',
        ]:
        ensure  => 'installed',
    }
}
