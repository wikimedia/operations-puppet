class varnish::packages($version='installed') {
    package { [
        'varnish',
        'varnish-dbg',
        'libvarnishapi1',
        ]:
        ensure  => $version,
    }

    # Install VMODs on Varnish 4 instances
    package { 'libvmod-header':
        ensure => 'absent',
    }
    package { [
        'varnish-modules',
        'libvmod-netmapper',
        'libvmod-tbf',
        'libvmod-vslp',
        ]:
        ensure  => 'installed',
        require => Package['libvmod-header'],
    }
}
