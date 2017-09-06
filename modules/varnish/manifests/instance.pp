define varnish::instance(
    $layer,
    $vcl_config,
    $ports,
    $admin_port,
    $instance_name='',
    $vcl = '',
    $storage='-s malloc,1G',
    $jemalloc_conf=undef,
    $runtime_parameters=[],
    $backend_caches={},
    $extra_vcl = [],
    $start_cmd_prefix = '',
) {

    include ::varnish::common

    $runtime_params = join(prefix($runtime_parameters, '-p '), ' ')
    if $instance_name == '' {
        $instancesuffix = ''
        $extraopts = ''
    }
    else {
        $instancesuffix = "-${instance_name}"
        $extraopts = "-n ${instance_name}"
    }

    # Install VCL include files shared by all instances
    require ::varnish::common::vcl

    $extra_vcl_variable_to_make_puppet_parser_happy = suffix($extra_vcl, " ${instancesuffix}")
    $extra_vcl_name = regsubst($extra_vcl_variable_to_make_puppet_parser_happy, '^([^ ]+) .*$', '\1')

    varnish::wikimedia_vcl { "/etc/varnish/${extra_vcl_name}.inc.vcl":
        template_path  => "varnish/${extra_vcl_name}.inc.vcl.erb",
        vcl            => $extra_vcl_name,
        vcl_config     => $vcl_config,
        before => Service["varnish${instancesuffix}"],
    }

    # Write the dynamic backend caches configuration, if we need it
    if $instance_name == '' {
        $inst = 'backend'
    } else {
        $inst = $instance_name
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

    varnish::wikimedia_vcl { "/etc/varnish/wikimedia-common_${vcl}.inc.vcl":
        template_path  => "${module_name}/vcl/wikimedia-common.inc.vcl.erb",
        vcl_config     => $vcl_config,
        backend_caches => $backend_caches,
        inst           => $inst,
    }

    varnish::wikimedia_vcl { "/etc/varnish/wikimedia_${vcl}.vcl":
        require        => File["/etc/varnish/${vcl}.inc.vcl"],
        template_path  => "${module_name}/vcl/wikimedia-${layer}.vcl.erb",
        vcl_config     => $vcl_config,
        backend_caches => $backend_caches,
        vcl            => $vcl,
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
        vcl_config      => $vcl_config,
        backend_caches  => $backend_caches,
        inst            => $inst,
    }

    varnish::wikimedia_vcl { "/usr/share/varnish/tests/wikimedia_${vcl}.vcl":
        require         => File['/usr/share/varnish/tests'],
        varnish_testing => true,
        template_path   => "${module_name}/vcl/wikimedia-${layer}.vcl.erb",
        vcl_config      => $vcl_config,
        backend_caches  => $backend_caches,
        vcl             => $vcl,
    }

    varnish::wikimedia_vcl { "/etc/varnish/${vcl}.inc.vcl":
        template_path  => "varnish/${vcl}.inc.vcl.erb",
        notify         => Exec["load-new-vcl-file${instancesuffix}"],
        vcl_config     => $vcl_config,
        backend_caches => $backend_caches,
    }

    varnish::wikimedia_vcl { "/usr/share/varnish/tests/${vcl}.inc.vcl":
        require         => File['/usr/share/varnish/tests'],
        varnish_testing => true,
        template_path   => "varnish/${vcl}.inc.vcl.erb",
        vcl_config      => $vcl_config,
        backend_caches  => $backend_caches,
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

    systemd::service { "varnish${instancesuffix}":
        content        => systemd_template('varnish'),
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
                Class['varnish::common::errorpage'],
                Class['varnish::common::browsersec'],
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

    # TODO/puppet4: convert this to be a define that uses instance name as title and ports as a parameter
    # to allow having non-strigified port numbers.
    varnish::monitoring::instance { $ports:
        instance => $title,
    }
}
