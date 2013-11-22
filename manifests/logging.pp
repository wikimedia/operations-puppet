define varnish::logging($listener_address, $port="8420", $cli_args="", $log_fmt=false, $instance_name="frontend", $monitor=true) {
    require varnish::packages,
        varnish::logging::config
    if $monitor {
        require varnish::logging::monitor
    }

    $varnishservice = $instance_name ? {
        "" => "varnish",
        default => "varnish-${instance_name}"
    }

    $shm_name = $instance_name ? {
        "" => $::hostname,
        default => $instance_name
    }

    file { "/etc/init.d/varnishncsa-${name}":
        content => template("${module_name}/varnishncsa.init.erb"),
        owner => root,
        group => root,
        mode => 0555,
        notify => Service["varnishncsa-${name}"];
    }

    service { "varnishncsa-${name}":
        require => [ File["/etc/init.d/varnishncsa-${name}"], Service[$varnishservice] ],
        subscribe => File["/etc/default/varnishncsa"],
        ensure => running,
        pattern => "/var/run/varnishncsa/varnishncsa-${name}.pid",
        hasstatus => false;
    }
}
