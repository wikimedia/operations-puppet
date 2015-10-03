class varnish::common::vcl {
    require varnish::common

    file { '/etc/varnish/geoip.inc.vcl':
        owner   => 'root',
        group   => 'root',
        mode    => '0444',
        content => template('varnish/geoip.inc.vcl.erb'),
    }

    file { '/etc/varnish/last-access.inc.vcl':
        ensure => absent,
    }

    file { '/etc/varnish/provenance.inc.vcl':
        ensure => absent,
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
        ensure => absent,
    }

    file { '/etc/varnish/hhvm.inc.vcl':
        ensure => absent,
        owner  => 'root',
        group  => 'root',
        mode   => '0444',
    }

    file { '/etc/varnish/analytics.inc.vcl':
        owner   => 'root',
        group   => 'root',
        mode    => '0444',
        content => template('varnish/analytics.inc.vcl.erb'),
    }

    # VCL unit tests
    file { '/usr/local/sbin/varnish-test-geoip':
        owner  => 'root',
        group  => 'root',
        mode   => '0555',
        source => 'puppet:///files/varnish/varnish-test-geoip',
    }
}
