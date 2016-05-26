define varnish::wikimedia_vcl($varnish_testing, $template_path) {
    if $varnish_testing  {
        $varnish_include_path = '/usr/share/varnish/tests/'
        $dynamic_directors = false
    }

    file { $title:
        owner   => 'root',
        group   => 'root',
        mode    => '0444',
        content => template($template_path),
    }
}

