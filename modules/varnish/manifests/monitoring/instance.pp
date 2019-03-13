define varnish::monitoring::instance($instance) {
    $port = $title
    monitoring::service { "varnish http ${instance} - port ${port}":
        description    => "Varnish HTTP ${instance} - port ${port}",
        check_command  => "check_http_varnish!varnishcheck!${port}",
        check_interval => 3,
        notes_url      => 'https://wikitech.wikimedia.org/wiki/Varnish',
    }
}
