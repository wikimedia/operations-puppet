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
    $xff_sources=[]
) {

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
        owner   => 'root',
        group   => 'root',
        mode    => '0555',
        content => template("${module_name}/varnish.init.erb"),
    }
    file { "/etc/default/varnish${instancesuffix}":
        owner   => 'root',
        group   => 'root',
        mode    => '0444',
        content => template("${module_name}/varnish-default.erb"),
    }
    file { "/etc/varnish/${vcl}.inc.vcl":
        owner   => 'root',
        group   => 'root',
        mode    => '0444',
        content => template("varnish/${vcl}.inc.vcl.erb"),
        notify  => Exec["load-new-vcl-file${instancesuffix}"],
    }
    file { "/etc/varnish/wikimedia_${vcl}.vcl":
        owner   => 'root',
        group   => 'root',
        mode    => '0444',
        require => File["/etc/varnish/${vcl}.inc.vcl"],
        content => template("${module_name}/vcl/wikimedia.vcl.erb"),
    }

    service { "varnish${instancesuffix}":
        ensure    => running,
        require   => [
                File["/etc/default/varnish${instancesuffix}"],
                File["/etc/init.d/varnish${instancesuffix}"],
                File["/etc/varnish/${vcl}.inc.vcl"],
                File["/etc/varnish/wikimedia_${vcl}.vcl"],
                Mount['/var/lib/varnish']
            ],
        hasstatus => false,
        pattern   => "/var/run/varnishd${instancesuffix}.pid",
        subscribe => Package['varnish'],
        before    => Exec['generate varnish.pyconf'],
    }

    # This mechanism with the touch/rm conditionals in the pair of execs
    #   below should ensure that reload-vcl failures are retried on
    #   future puppet runs until they succeed.
    $vcl_failed_file = "/var/tmp/reload-vcl-failed${instancesuffix}"

    exec { "load-new-vcl-file${instancesuffix}":
        require     => [
                Service["varnish${instancesuffix}"],
                File["/etc/varnish/wikimedia_${vcl}.vcl"]
            ],
        subscribe   => [
                Class['varnish::common::vcl'],
                File[suffix(prefix($extra_vcl, '/etc/varnish/'),".inc.vcl")],
                File["/etc/varnish/wikimedia_${vcl}.vcl"]
            ],
        command     => "/usr/share/varnish/reload-vcl ${extraopts} || (touch ${vcl_failed_file}; false)",
        unless      => "test -f ${vcl_failed_file}",
        path        => '/bin:/usr/bin',
        refreshonly => true,
    }

    exec { "retry-load-new-vcl-file${instancesuffix}":
        require     => Exec["load-new-vcl-file${instancesuffix}"],
        command     => "/usr/share/varnish/reload-vcl ${extraopts} && (rm ${vcl_failed_file}; true)",
        onlyif      => "test -f ${vcl_failed_file}",
        path        => '/bin:/usr/bin',
    }

    monitor_service { "varnish http ${title}":
        description   => "Varnish HTTP ${title}",
        check_command => "check_http_generic!varnishcheck!${port}"
    }

    # Restart gmond if this varnish instance has been (re)started later
    # than gmond was started
    exec { "restart gmond for varnish${instancesuffix}":
        path    => '/bin:/usr/bin',
        command => 'true',
        onlyif  => "test /var/run/varnishd${instancesuffix}.pid -nt /var/run/gmond.pid",
        notify  => Service['gmond'],
    }
}
