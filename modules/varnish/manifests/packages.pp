class varnish::packages($version='installed') {
    require varnish::apt_preferences

    package { [
        'varnish',
        'varnish-dbg',
        'libvarnishapi1',
        ]:
        ensure  => $version,
        require => Class['varnish::apt_preferences'],
    }

    if (hiera('varnish_version4', false)) {
        # Install VMODs on Varnish 4 instances
        package { [
            'libvmod-netmapper',
            'libvmod-tbf',
            'libvmod-vslp',
            'varnish-modules'
            ]:
            ensure  => 'installed',
            require => Class['varnish::apt_preferences'],
        }
    }
}
