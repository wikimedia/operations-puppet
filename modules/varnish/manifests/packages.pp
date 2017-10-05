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
        ]:
        ensure  => 'installed',
    }

    if (hiera('varnish::major_version', 4) == 4) {
        package { 'libvmod-vslp':
            ensure => 'installed',
        }
    }
}
