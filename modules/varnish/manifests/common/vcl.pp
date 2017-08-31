class varnish::common::vcl {
    require ::varnish::common
    require ::varnish::common::errorpage
    require ::varnish::common::browsersec

    file { '/etc/varnish/analytics.inc.vcl':
        owner   => 'root',
        group   => 'root',
        mode    => '0444',
        content => template('varnish/analytics.inc.vcl.erb'),
    }

    # VTC tests
    file { '/usr/share/varnish/tests/':
        source  => 'puppet:///modules/varnish/tests',
        owner   => 'root',
        group   => 'root',
        mode    => '0644',
        recurse => true,
    }

    file { '/usr/local/bin/varnishtest-runner':
        ensure => absent,
    }
}
