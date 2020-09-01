class varnish::packages($version='installed') {
    package { [
        'varnish',
        'varnish-dbg',
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
