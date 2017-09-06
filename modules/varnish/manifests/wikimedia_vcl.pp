define varnish::wikimedia_vcl(
    $varnish_testing = false,
    $template_path = '',
    $notify = undef,
    $require = undef,
) {
    if $varnish_testing  {
        $varnish_include_path = '/usr/share/varnish/tests/'
        $dynamic_backend_caches = false
        $netmapper_dir = $varnish_include_path
    } else {
        $varnish_include_path = ''
        $dynamic_backend_caches = hiera('varnish::dynamic_backend_caches', true)
        $netmapper_dir = '/var/netmapper'
    }

    # Hieradata switch to shut users out of a DC/cluster. T129424
    $traffic_shutdown = hiera('cache::traffic_shutdown', false)

    file { $title:
        owner   => 'root',
        group   => 'root',
        mode    => '0444',
        content => template($template_path),
        notify  => $notify,
        require => $require,
    }
}

