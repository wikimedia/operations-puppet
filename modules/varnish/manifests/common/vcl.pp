class varnish::common::vcl {
    require varnish::common

    file { '/etc/varnish/geoip.inc.vcl':
        owner   => 'root',
        group   => 'root',
        mode    => '0444',
        content => template('varnish/geoip.inc.vcl.erb'),
    }

    file { '/etc/varnish/last-access.inc.vcl':
        owner   => 'root',
        group   => 'root',
        mode    => '0444',
        content => template('varnish/last-access.inc.vcl.erb'),
    }

    file { '/etc/varnish/static-hash.inc.vcl':
        owner   => 'root',
        group   => 'root',
        mode    => '0444',
        content => template('varnish/static-hash.inc.vcl.erb'),
    }

    file { '/etc/varnish/provenance.inc.vcl':
        owner   => 'root',
        group   => 'root',
        mode    => '0444',
        content => template('varnish/provenance.inc.vcl.erb'),
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


    file { '/etc/varnish/via.inc.vcl':
        owner   => 'root',
        group   => 'root',
        mode    => '0444',
        content => template('varnish/via.inc.vcl.erb'),
    }

    file { '/etc/varnish/hhvm.inc.vcl':
        ensure  => absent,
        owner   => 'root',
        group   => 'root',
        mode    => '0444',
    }

    # VCL unit tests
    file { '/usr/local/sbin/varnish-test-geoip':
        owner  => 'root',
        group  => 'root',
        mode   => '0555',
        source => 'puppet:///files/varnish/varnish-test-geoip',
    }
}
