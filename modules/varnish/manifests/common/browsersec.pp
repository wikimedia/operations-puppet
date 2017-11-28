class varnish::common::browsersec {
    $errorpage = {
        title       => 'Browser Connection Security Issues',
        pagetitle   => "Your Browser's Connection Security is Outdated",
        logo_link   => 'https://www.wikimedia.org',
        logo_src    => 'https://www.wikimedia.org/static/images/wmf-logo.png',
        logo_srcset => 'https://www.wikimedia.org/static/images/wmf-logo-2x.png 2x',
        logo_width  => '135',
        logo_height => '101',
        logo_alt    => 'Wikimedia',
        content     => template('varnish/browsersec.body.html.erb'),
    }
    $error_browsersec_html = template('mediawiki/errorpage.html.erb')

    file { '/etc/varnish/browsersec.inc.vcl':
        owner   => 'root',
        group   => 'root',
        mode    => '0444',
        content => template('varnish/browsersec.inc.vcl.erb'),
    }
}
