class varnish::packages($version='installed') {
    package { [
        'varnish',
        'varnish-dbg',
        'libvarnishapi1',
        ]:
        ensure => $version
    }
}
