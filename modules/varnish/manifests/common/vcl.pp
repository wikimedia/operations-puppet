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

    $unsatisfiable_status = 416
    $unsatisfiable_length = 0

    file { '/usr/local/bin/varnishtest-runner':
        owner   => 'root',
        group   => 'root',
        mode    => '0755',
        content => template("${module_name}/varnishtest-runner.sh.erb"),
    }
}
