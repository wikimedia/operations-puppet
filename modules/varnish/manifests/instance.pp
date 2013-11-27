define varnish::instance(
    $name="",
    $vcl = "",
    $vcl_config,
    $port="80",
    $admin_port="6083",
    $storage="-s malloc,1G",
    $runtime_parameters=[],
    $backends=undef,
    $directors={},
    $director_type="hash",
    $director_options={},
    $extra_vcl = [],
    $backend_options,
    $cluster_options={},
    $wikimedia_networks=[],
    $xff_sources=[]) {

    include varnish::common

    $runtime_params = join(prefix($runtime_parameters, "-p "), " ")
    if $name == "" {
        $instancesuffix = ""
        $extraopts = ""
    }
    else {
        $instancesuffix = "-${name}"
        $extraopts = "-n ${name}"
    }

    # Initialize variables for templates
    # FIXME: get rid of the $varnish_* below and update the templates
    $varnish_port = $port
    $varnish_admin_port = $admin_port
    $varnish_storage = $storage
    $varnish_backends = $backends ? { undef => sort(unique(flatten(values($directors)))), default => $backends }
    $varnish_directors = $directors
    $varnish_backend_options = $backend_options
    # $cluster_option is referenced directly

    # Install VCL include files shared by all instances
    require varnish::common::vcl

    $extra_vcl_variable_to_make_puppet_parser_happy = suffix($extra_vcl, " ${instancesuffix}")
    extra_vcl{ $extra_vcl_variable_to_make_puppet_parser_happy:
        before => Service["varnish${instancesuffix}"]
    }

    file { "/etc/init.d/varnish${instancesuffix}":
            content => template("${module_name}/varnish.init.erb"),
            mode    => '0555',
    }
    file { "/etc/default/varnish${instancesuffix}":
            content => template("${module_name}/varnish-default.erb"),
            mode    => '0444',
    }
    file { "/etc/varnish/${vcl}.inc.vcl":
            content => template("varnish/${vcl}.inc.vcl.erb"),
            notify  => Exec["load-new-vcl-file${instancesuffix}"],
            mode    => '0444',
    }
    file { "/etc/varnish/wikimedia_${vcl}.vcl":
            require => File["/etc/varnish/${vcl}.inc.vcl"],
            content => template("${module_name}/vcl/wikimedia.vcl.erb"),
            mode    => '0444',
    }

    service { "varnish${instancesuffix}":
        ensure    => running,
        require   => [
                File[
                    "/etc/default/varnish${instancesuffix}",
                    "/etc/init.d/varnish${instancesuffix}",
                    "/etc/varnish/${vcl}.inc.vcl",
                    "/etc/varnish/wikimedia_${vcl}.vcl"
                ],
                Mount['/var/lib/varnish']
            ],
        hasstatus => false,
        pattern   => "/var/run/varnishd${instancesuffix}.pid",
        subscribe => Package[varnish],
        before    => Exec['generate varnish.pyconf'],
    }

    exec { "load-new-vcl-file${instancesuffix}":
        require     => [ Service["varnish${instancesuffix}"], File["/etc/varnish/wikimedia_${vcl}.vcl"] ],
        subscribe   => [ Class[varnish::common::vcl],
                         File[suffix(prefix($extra_vcl, '/etc/varnish/'),".inc.vcl"),
                              "/etc/varnish/wikimedia_${vcl}.vcl"],],
        command     => "/usr/share/varnish/reload-vcl ${extraopts}",
        path        => '/bin:/usr/bin',
        refreshonly => true,
    }

    monitor_service { "varnish http ${title}":
        description   => "Varnish HTTP ${title}",
        check_command => "check_http_generic!varnishcheck!${port}"
    }

    # Restart gmond if this varnish instance has been (re)started later
    # than gmond was started
    exec { "restart gmond for varnish${instancesuffix}":
        command => '/bin/true',
        onlyif  => "test /var/run/varnishd${instancesuffix}.pid -nt /var/run/gmond.pid",
        notify  => Service['gmond'],
    }
}
