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

    $errorpage  = {
        title       => 'Wikimedia Error',
        content     => '<p>Our servers are currently under maintenance or experiencing a technical problem. Please <a href="" title="Reload this page" onclick="window.location.reload(false); return false">try again</a> in a few&nbsp;minutes.</p><p>See the error message at the bottom of this page for more&nbsp;information.</p>',
        # Use append instead of footer because we intentionally leave the
        # "div.footer > p > code" stack unclosed.
        # We then let errorpage.incl.vcl concatenate and close the stack.
        append      => '<div class="footer"><p>If you report this error to the Wikimedia System Administrators, please include the details below.</p><p class="text-muted"><code>',
    }
    file { '/etc/varnish/errorpage.html':
        owner  => 'root',
        group  => 'root',
        mode   => '0444',
        source => template('mediawiki/errorpage.html.erb'),
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
