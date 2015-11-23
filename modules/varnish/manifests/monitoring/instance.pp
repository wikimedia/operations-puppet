define varnish::monitoring::instance() {
    $port = $title
    monitoring::service { "varnish http ${title} - port $port":
        description   => "Varnish HTTP ${title} - port $port",
        check_command => "check_http_varnish!varnishcheck!${port}"
    }
}
