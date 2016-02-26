class varnish::common::vcl {
    require varnish::common

    $varnish_version4 = hiera('varnish_version4', false)

    file { '/etc/varnish/geoip.inc.vcl':
        owner   => 'root',
        group   => 'root',
        mode    => '0444',
        content => template('varnish/geoip.inc.vcl.erb'),
    }

    file { '/etc/varnish/errorpage.inc.vcl':
        owner   => 'root',
        group   => 'root',
        mode    => '0444',
        content => template('varnish/errorpage.inc.vcl.erb'),
    }

    file { '/etc/varnish/analytics.inc.vcl':
        owner   => 'root',
        group   => 'root',
        mode    => '0444',
        content => template('varnish/analytics.inc.vcl.erb'),
    }

    file { '/etc/varnish/errorpage_head.html':
        owner   => 'root',
        group   => 'root',
        mode    => '0444',
	source  => 'puppet:///files/varnish/errorpage_head.html',
    }

    # VCL unit tests
    file { '/usr/local/sbin/varnish-test-geoip':
        owner  => 'root',
        group  => 'root',
        mode   => '0555',
        source => 'puppet:///modules/varnish/varnish-test-geoip',
    }

    file { '/usr/share/varnish/tests/':
        source  => 'puppet:///modules/varnish/tests',
        recurse => true,
    }
}
