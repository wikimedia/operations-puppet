class varnish::common::browsersec {
    $errorpage = {
        title              => 'Browser Connection Security Issues',
        pagetitle          => "Your Browser's Connection Security is Outdated",
        content            => template('varnish/browsersec.body.html.erb'),
        browsersec_comment => true,
    }
    $error_browsersec_html = mediawiki::errorpage_content($errorpage)

    file { '/etc/varnish/browsersec.inc.vcl':
        owner     => 'root',
        group     => 'root',
        mode      => '0444',
        content   => template('varnish/browsersec.inc.vcl.erb'),
        show_diff => false,
    }
}
