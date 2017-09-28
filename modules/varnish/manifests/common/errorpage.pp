class varnish::common::errorpage {
    $errorpage = {
        title       => 'Wikimedia Error',
        pagetitle   => 'Error',
        logo_link   => 'https://www.wikimedia.org',
        logo_src    => 'https://www.wikimedia.org/static/images/wmf-logo.png',
        logo_srcset => 'https://www.wikimedia.org/static/images/wmf-logo-2x.png 2x',
        logo_alt    => 'Wikimedia',
        content     => template('varnish/errorpage.body.html.erb'),
        # Placeholder "%error%" substituted at runtime in errorpage.inc.vcl
        footer      => template('varnish/errorpage.footer.html.erb'),
    }
    $errorpage_html = template('mediawiki/errorpage.html.erb')

    file { '/etc/varnish/errorpage.inc.vcl':
        owner   => 'root',
        group   => 'root',
        mode    => '0444',
        content => template('varnish/errorpage.inc.vcl.erb'),
    }
}
