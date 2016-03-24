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
}
