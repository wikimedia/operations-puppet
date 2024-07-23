class varnish::common::errorpage {
    $errorpage = {
        title       => 'Wikimedia Error',
        pagetitle   => 'Error',
        logo_link   => 'https://www.wikimedia.org',
        logo_src    => 'https://www.wikimedia.org/static/images/wmf-logo.png',
        logo_srcset => 'https://www.wikimedia.org/static/images/wmf-logo-2x.png 2x',
        logo_width  => 135,
        logo_height => 101,
        logo_alt    => 'Wikimedia',
        content     => '<p>%error_body_content%</p>',
        # Placeholder "%error%" substituted at runtime in errorpage.inc.vcl
        footer      => template('varnish/errorpage.footer.html.erb'),
    }
    $errorpage_html = mediawiki::errorpage_content($errorpage)

    file { '/etc/varnish/errorpage.inc.vcl':
        owner   => 'root',
        group   => 'root',
        mode    => '0444',
        content => template('varnish/errorpage.inc.vcl.erb'),
    }
}
