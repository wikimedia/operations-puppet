class varnish::common::vcl {
    require varnish::common

    file { '/etc/varnish/geoip.inc.vcl':
        owner   => 'root',
        group   => 'root',
        mode    => '0444',
        content => template('varnish/geoip.inc.vcl.erb'),
    }
    file { '/etc/varnish/device-detection.inc.vcl':
        ensure  => absent,
    }
    file { '/etc/varnish/errorpage.inc.vcl':
        owner   => 'root',
        group   => 'root',
        mode    => '0444',
        content => template('varnish/errorpage.inc.vcl.erb'),
    }

    # VCL unit tests
    file { '/usr/local/sbin/varnish-test-geoip':
        owner  => 'root',
        group  => 'root',
        mode   => '0555',
        source => 'puppet:///files/varnish/varnish-test-geoip',
    }
}
