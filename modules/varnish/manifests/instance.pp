define varnish::instance(
    $layer,
    $vcl_config,
    $ports,
    $admin_port,
    $name='',
    $vcl = '',
    $storage='-s malloc,1G',
    $jemalloc_conf=undef,
    $runtime_parameters=[],
    $app_directors={},
    $app_def_be_opts={},
    $backend_caches={},
    $extra_vcl = []
) {

    include ::varnish::common

    $runtime_params = join(prefix($runtime_parameters, '-p '), ' ')
    if $name == '' {
        $instancesuffix = ''
        $extraopts = ''
    }
    else {
        $instancesuffix = "-${name}"
        $extraopts = "-n ${name}"
    }

    $netmapper_dir = '/var/netmapper'

    $dynamic_backend_caches = hiera('varnish::dynamic_backend_caches', true)

    # Install VCL include files shared by all instances
    require ::varnish::common::vcl

    $extra_vcl_variable_to_make_puppet_parser_happy = suffix($extra_vcl, " ${instancesuffix}")
    extra_vcl{ $extra_vcl_variable_to_make_puppet_parser_happy:
        before => Service["varnish${instancesuffix}"],
    }

    # Write the dynamic backend caches configuration, if we need it
    if $name == '' {
        $inst = 'backend'
    } else {
        $inst = $name
    }

    varnish::common::directors { $vcl:
        instance  => $inst,
        directors => $backend_caches,
        extraopts => $extraopts,
        before    => [
            File["/etc/varnish/wikimedia_${vcl}.vcl"],
            Service["varnish${instancesuffix}"]
        ],
    }

    # Hieradata switch to shut users out of a DC/cluster. T129424
    $traffic_shutdown = hiera('cache::traffic_shutdown', false)

    file { "/etc/varnish/wikimedia-common_${vcl}.inc.vcl":
        owner   => 'root',
        group   => 'root',
        mode    => '0444',
        content => template("${module_name}/vcl/wikimedia-common.inc.vcl.erb"),
    }

    file { "/etc/varnish/wikimedia_${vcl}.vcl":
        owner   => 'root',
        group   => 'root',
        mode    => '0444',
        require => File["/etc/varnish/${vcl}.inc.vcl"],
        content => template("${module_name}/vcl/wikimedia-${layer}.vcl.erb"),
    }

    # These versions of wikimedia-common_${vcl}.vcl and wikimedia_${vcl}.vcl
    # are exactly the same as those under /etc/varnish but without any
    # backends defined. The goal is to make it possible to run the VTC test
    # files under /usr/share/varnish/tests without having to modify any VCL
    # file by hand.
    varnish::wikimedia_vcl { "/usr/share/varnish/tests/wikimedia-common_${vcl}.inc.vcl":
        require         => File['/usr/share/varnish/tests'],
        varnish_testing => true,
        template_path   => "${module_name}/vcl/wikimedia-common.inc.vcl.erb",
    }

    varnish::wikimedia_vcl { "/usr/share/varnish/tests/wikimedia_${vcl}.vcl":
        require         => File['/usr/share/varnish/tests'],
        varnish_testing => true,
        template_path   => "${module_name}/vcl/wikimedia-${layer}.vcl.erb",
    }

    file { "/etc/varnish/${vcl}.inc.vcl":
        owner   => 'root',
        group   => 'root',
        mode    => '0444',
        content => template("varnish/${vcl}.inc.vcl.erb"),
        notify  => Exec["load-new-vcl-file${instancesuffix}"],
    }

    varnish::wikimedia_vcl { "/usr/share/varnish/tests/${vcl}.inc.vcl":
        require         => File['/usr/share/varnish/tests'],
        varnish_testing => true,
        template_path   => "varnish/${vcl}.inc.vcl.erb",
    }

    # The defaults file is also parsed by /usr/share/varnish/reload-vcl,
    #   even under systemd where the init part itself does not.  This
    #   situation should be cleaned up later after all varnishes are on
    #   systemd.
    file { "/etc/default/varnish${instancesuffix}":
        owner   => 'root',
        group   => 'root',
        mode    => '0444',
        content => template("${module_name}/varnish-default.erb"),
    }

    base::service_unit { "varnish${instancesuffix}":
        template_name  => 'varnish',
        systemd        => true,
        refresh        => false,
        service_params => {
            tag     => 'varnish_instance',
            enable  => true,
            require => [
                Package['varnish'],
                File["/etc/default/varnish${instancesuffix}"],
                File["/etc/varnish/${vcl}.inc.vcl"],
                File["/etc/varnish/wikimedia_${vcl}.vcl"],
                File["/etc/varnish/wikimedia-common_${vcl}.inc.vcl"],
                Mount['/var/lib/varnish'],
            ],
        },
    }

    # This mechanism with the touch/rm conditionals in the pair of execs
    #   below should ensure that reload-vcl failures are retried on
    #   future puppet runs until they succeed.
    $vcl_failed_file = "/var/tmp/reload-vcl-failed${instancesuffix}"

    exec { "load-new-vcl-file${instancesuffix}":
        require     => Service["varnish${instancesuffix}"],
        subscribe   => [
                Class['varnish::common::vcl'],
                File[suffix(prefix($extra_vcl, '/etc/varnish/'),'.inc.vcl')],
                File["/etc/varnish/wikimedia_${vcl}.vcl"],
                File["/etc/varnish/wikimedia-common_${vcl}.inc.vcl"],
            ],
        command     => "/usr/share/varnish/reload-vcl ${extraopts} || (touch ${vcl_failed_file}; false)",
        unless      => "test -f ${vcl_failed_file}",
        path        => '/bin:/usr/bin',
        refreshonly => true,
    }

    exec { "retry-load-new-vcl-file${instancesuffix}":
        require => Exec["load-new-vcl-file${instancesuffix}"],
        command => "/usr/share/varnish/reload-vcl ${extraopts} && (rm ${vcl_failed_file}; true)",
        onlyif  => "test -f ${vcl_failed_file}",
        path    => '/bin:/usr/bin',
    }

    varnish::monitoring::instance { $ports:
        instance => $title,
    }
}
