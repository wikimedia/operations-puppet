class varnish::common::vcl {
    require varnish::common

    $varnish_version4 = hiera('varnish_version4', false)

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

    file { '/etc/varnish/errorpage.html':
        owner  => 'root',
        group  => 'root',
        mode   => '0444',
        source => 'puppet:///modules/varnish/errorpage.html',
    }

    # VCL unit tests
    file { '/usr/local/sbin/varnish-test-geoip':
        owner  => 'root',
        group  => 'root',
        mode   => '0555',
        source => 'puppet:///modules/varnish/varnish-test-geoip',
    }

    # VTC tests
    file { '/usr/share/varnish/tests/':
        source  => 'puppet:///modules/varnish/tests',
        owner   => 'root',
        group   => 'root',
        recurse => true,
    }

    if $varnish_version4 {
        $unsatisfiable_status = 416
        $unsatisfiable_length = 0
    } else {
        $unsatisfiable_status = 200
        $unsatisfiable_length = 20
    }

    file { '/usr/local/bin/varnishtest-runner':
        owner   => 'root',
        group   => 'root',
        mode    => '0755',
        content => template("${module_name}/test-runner.sh.erb"),
    }
}
