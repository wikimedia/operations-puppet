class varnish::common::vcl {
    require ::varnish::common

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
