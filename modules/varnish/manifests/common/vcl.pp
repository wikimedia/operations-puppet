class varnish::common::vcl {
    require ::varnish::common

    $errorpage = {
        title => 'Wikimedia Error',
        pagetitle => 'Error',
        logo_link => 'https://www.wikimedia.org',
        logo_src => 'https://www.wikimedia.org/static/images/wmf.png',
        logo_srcset => 'https://www.wikimedia.org/static/images/wmf-2x.png 2x',
        logo_alt => 'Wikimedia',
        content  => template('varnish/errorpage.body.html.erb'),
        footer   => template('varnish/errorpage.footer.html.erb'),
    }
    $errorpage_html = template('mediawiki/errorpage.html.erb')

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
