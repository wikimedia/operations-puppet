class varnish::common::errorpage {
    # Placeholder "%error_body_content%" (content) and "%error%" (footer)
    # are substituted at runtime in errorpage.inc.vcl
    $errorpage_html = mediawiki::errorpage_content({
        content     => '<p>%error_body_content%</p>',
        footer      => template('varnish/errorpage.footer.html.erb'),
    })

    file { '/etc/varnish/errorpage.inc.vcl':
        owner   => 'root',
        group   => 'root',
        mode    => '0444',
        content => template('varnish/errorpage.inc.vcl.erb'),
    }
}
