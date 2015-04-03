define varnish::logging(
    $listener_address,
    $port='8420',
    $cli_args='',
    $log_fmt=false,
    $instance_name='frontend',
    $monitor=true,
    $ensure='running',
) {
    require varnish::packages
    require varnish::logging::config

    if $monitor {
        require varnish::logging::monitor
    }

    $varnishservice = $instance_name ? {
        ''      => 'varnish',
        default => "varnish-${instance_name}"
    }

    $shm_name = $instance_name ? {
        ''      => $::hostname,
        default => $instance_name
    }

    base::service_unit { "varnishncsa-${name}":
        ensure        => $ensure,
        template_name => 'varnishncsa',
        sysvinit      => true,
    }

    Service[$varnishservice] -> Service["varnishncsa-${name}"]
    File['/etc/default/varnishncsa'] ~> Service["varnishncsa-${name}"]
}
