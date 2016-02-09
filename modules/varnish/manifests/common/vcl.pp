class varnish::common::vcl {
    require varnish::common

    if hiera('varnish_version4', false) {
        $vcl_version_suffix = '_v4'
    }
    else {
        $vcl_version_suffix = ''
    }

    file { '/etc/varnish/geoip.inc.vcl':
        owner   => 'root',
        group   => 'root',
        mode    => '0444',
        content => template('varnish/geoip.inc.vcl.erb'),
    }

    file { "/etc/varnish/errorpage${vcl_version_suffix}.inc.vcl":
        owner   => 'root',
        group   => 'root',
        mode    => '0444',
        content => template("varnish/errorpage${vcl_version_suffix}.inc.vcl.erb"),
    }

    file { "/etc/varnish/analytics${vcl_version_suffix}.inc.vcl":
        owner   => 'root',
        group   => 'root',
        mode    => '0444',
        content => template("varnish/analytics${vcl_version_suffix}.inc.vcl.erb"),
    }

    # VCL unit tests
    file { '/usr/local/sbin/varnish-test-geoip':
        owner  => 'root',
        group  => 'root',
        mode   => '0555',
        source => 'puppet:///modules/varnish/varnish-test-geoip',
    }
}
