define varnish::wikimedia_vcl($varnish_testing, $template_path) {
    if $varnish_testing  {
        $varnish_include_path = '/usr/share/varnish/tests/'
        $dynamic_backend_caches = false
        $netmapper_dir = $varnish_include_path

        # Mock VCL config for varnishtest
        $vcl_config = {
            'top_domain'       => 'org',
            'shortener_domain' => 'w.wiki',
            'upload_domain'    => 'upload.wikimedia.org',
            'purge_host_regex' => '^(?!upload\.wikimedia\.org)',
            'static_host'      => 'en.wikipedia.org',
            'req_handling'     => {},
            'grace_healthy'    => '5s',
            'grace_sick'       => '10s',
            'keep'             => '15s',
        }
    }

    file { $title:
        owner   => 'root',
        group   => 'root',
        mode    => '0444',
        content => template($template_path),
    }
}

