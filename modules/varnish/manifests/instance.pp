define varnish::instance(
    $layer,
    $vcl_config,
    $ports,
    $admin_port,
    $instance_name='',
    $vcl = '',
    $storage='-s malloc,1G',
    $jemalloc_conf=undef,
    $app_directors={},
    $app_def_be_opts={},
    $backend_caches={},
    $extra_vcl = []
) {

    include ::varnish::common

    if $instance_name == '' {
        $instancesuffix = ''
        $instance_opt = ''
    }
    else {
        $instancesuffix = "-${instance_name}"
        $instance_opt = "-n ${instance_name}"
    }

    # T157430 - vcl reloads should delay between load and use for the whole
    # probe window to avoid possibility of spurious 503s.
    # 5 probe window -> timeout*5 + interval*4, then round up whole seconds,
    # then set a sane mininum of 2s
    $vcl_reload_delay_s = max(2, ceiling((($vcl_config['varnish_probe_ms'] * 5) + (100 * 4)) / 1000.0))

    $vcl_file_opt = "-f /etc/varnish/wikimedia_${vcl}.vcl"
    $reload_vcl_opts = "${instance_opt} ${vcl_file_opt} -d ${vcl_reload_delay_s} -a"

    # Install VCL include files shared by all instances
    require ::varnish::common::vcl

    $extra_vcl_variable_to_make_puppet_parser_happy = suffix($extra_vcl, " ${instancesuffix}")
    varnish::wikimedia_vcl { $extra_vcl_variable_to_make_puppet_parser_happy:
        generate_extra_vcl => true,
        vcl_config         => $vcl_config,
        before             => Service["varnish${instancesuffix}"],
    }

    # Write the dynamic backend caches configuration, if we need it
    if $instance_name == '' {
        $inst = 'backend'
        $runtime_parameters = $::varnish::common::be_runtime_params
    } else {
        $inst = $instance_name
        $runtime_parameters = $::varnish::common::fe_runtime_params
    }

    # Raise an icinga warning if the Varnish child process has been started
    # more than once; that means it has died unexpectedly. Critical if it has
    # been started more than 3 times.
    $prometheus_labels = "instance=~\"${::hostname}:.*\",layer=\"${inst}\""

    monitoring::check_prometheus { "varnish-${inst}-check-child-start":
        description     => "Varnish ${inst} child restarted",
        dashboard_links => ["https://grafana.wikimedia.org/dashboard/db/varnish-machine-stats?panelId=66&fullscreen&orgId=1&var-server=${::hostname}&var-datasource=${::site} prometheus/ops"],
        query           => "scalar(varnish_mgt_child_start{${prometheus_labels}})",
        method          => 'gt',
        warning         => 1,
        critical        => 3,
        prometheus_url  => "http://prometheus.svc.${::site}.wmnet/ops",
    }

    $runtime_params = join(prefix($runtime_parameters, '-p '), ' ')

    varnish::common::directors { $vcl:
        instance        => $inst,
        directors       => $backend_caches,
        reload_vcl_opts => $reload_vcl_opts,
        before          => [
            File["/etc/varnish/wikimedia_${vcl}.vcl"],
            Service["varnish${instancesuffix}"]
        ],
    }

    varnish::wikimedia_vcl { "/etc/varnish/wikimedia-common_${vcl}.inc.vcl":
        template_path   => "${module_name}/vcl/wikimedia-common.inc.vcl.erb",
        vcl_config      => $vcl_config,
        backend_caches  => $backend_caches,
        inst            => $inst,
        app_directors   => $app_directors,
        app_def_be_opts => $app_def_be_opts,
    }

    varnish::wikimedia_vcl { "/etc/varnish/wikimedia_${vcl}.vcl":
        require         => File["/etc/varnish/${vcl}.inc.vcl"],
        template_path   => "${module_name}/vcl/wikimedia-${layer}.vcl.erb",
        vcl_config      => $vcl_config,
        backend_caches  => $backend_caches,
        vcl             => $vcl,
        app_directors   => $app_directors,
        app_def_be_opts => $app_def_be_opts,
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
        app_directors   => $app_directors,
        app_def_be_opts => $app_def_be_opts,
    }

    varnish::wikimedia_vcl { "/usr/share/varnish/tests/wikimedia_${vcl}.vcl":
        require         => File['/usr/share/varnish/tests'],
        varnish_testing => true,
        template_path   => "${module_name}/vcl/wikimedia-${layer}.vcl.erb",
        vcl_config      => $vcl_config,
        backend_caches  => $backend_caches,
        vcl             => $vcl,
        app_directors   => $app_directors,
        app_def_be_opts => $app_def_be_opts,
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

    if ($inst == 'backend') {
        # -sfile needs CAP_DAC_OVERRIDE and CAP_FOWNER too
        $capabilities = 'CAP_SETUID CAP_SETGID CAP_CHOWN CAP_DAC_OVERRIDE CAP_FOWNER'
    } else {
        # varnish frontend needs CAP_NET_BIND_SERVICE as it binds to port 80
        $capabilities = 'CAP_SETUID CAP_SETGID CAP_CHOWN CAP_NET_BIND_SERVICE'
    }

    base::service_unit { "varnish${instancesuffix}":
        systemd        => systemd_template('varnish'),
        refresh        => false,
        service_params => {
            tag     => 'varnish_instance',
            enable  => true,
            require => [
                Package['varnish'],
                File["/etc/varnish/${vcl}.inc.vcl"],
                File["/etc/varnish/wikimedia_${vcl}.vcl"],
                File["/etc/varnish/wikimedia-common_${vcl}.inc.vcl"],
                Mount['/var/lib/varnish'],
            ],
        },
    }

    require_package('python-logstash')

    systemd::service { "varnish${instancesuffix}-slowlog":
        ensure         => present,
        content        => systemd_template('varnishslowlog'),
        restart        => true,
        service_params => {
            require => Service["varnish${instancesuffix}"],
            enable  => true,
        },
        require        => File['/usr/local/bin/varnishslowlog'],
        subscribe      => File['/usr/local/bin/varnishslowlog'],
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
        command     => "/usr/share/varnish/reload-vcl ${reload_vcl_opts} || (touch ${vcl_failed_file}; false)",
        unless      => "test -f ${vcl_failed_file}",
        path        => '/bin:/usr/bin',
        refreshonly => true,
    }

    exec { "retry-load-new-vcl-file${instancesuffix}":
        require => Exec["load-new-vcl-file${instancesuffix}"],
        command => "/usr/share/varnish/reload-vcl ${reload_vcl_opts} && (rm ${vcl_failed_file}; true)",
        onlyif  => "test -f ${vcl_failed_file}",
        path    => '/bin:/usr/bin',
    }

    # TODO/puppet4: convert this to be a define that uses instance name as title and ports as a parameter
    # to allow having non-strigified port numbers.
    varnish::monitoring::instance { $ports:
        instance => $title,
    }
}
