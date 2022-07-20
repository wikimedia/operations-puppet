# @summary configuera a varnish instance
# @param vcl_config A hash if vcl config
# @param ports a list of ports to listen on
# @param admin_port the port for admin operations
# @param runtime_params A hash of runtime parameters
# @param instance_name the name of the varnish instance
# @param vcl name of the VCL to use
# @param storage The varnish daemon storage parameters
# @param jemalloc_conf jemalloc configuration
# @param backend_caches list of backend caches
# @param backend_options hash of backend configs
# @param backends_in_etcd indicate if backends are in etcd
# @param extra_vcl list of extra VCLs
# @param separate_vcl list of addtional VCLs
# @param wikimedia_nets wikimedia owned networks
# @param wikimedia_trust wikimedia owned truested
# @param wikimedia_domains a list of wikimedia productions domains
# @param wmcs_domains a list of wikimedia cloud services domains
# @param listen_uds list of uds for varnish
# @param uds_owner The owner of the uds sockets
# @param uds_group The group of the uds sockets
# @param uds_mode The mode of the uds sockets
define varnish::instance(
    Hash                    $vcl_config,
    Array[Stdlib::Port]     $ports,
    Stdlib::Port            $admin_port,
    String                  $runtime_params,
    # TODO: change this to Optional[String]
    String                  $instance_name     = '',
    # TODO: I think we can make this mandatory?
    String                  $vcl               = '',
    String                  $storage           = '-s malloc,1G',
    Optional[String]        $jemalloc_conf     = undef,
    Array                   $backend_caches    = [],
    Hash                    $backend_options   = {},
    Boolean                 $backends_in_etcd  = true,
    Array                   $extra_vcl         = [],
    Array                   $separate_vcl      = [],
    Array                   $wikimedia_nets    = [],
    Array                   $wikimedia_trust   = [],
    Array[Stdlib::Fqdn]     $wikimedia_domains = [],
    Array[Stdlib::Fqdn]     $wmcs_domains      = [],
    Array[Stdlib::Unixpath] $listen_uds        = [],
    String                  $uds_owner         = 'root',
    String                  $uds_group         = 'root',
    Stdlib::Filemode        $uds_mode          = '700',
) {

    include varnish::common

    if $instance_name == '' {
        $instancesuffix = ''
        $instance_opt = ''
    }
    else {
        $instancesuffix = "-${instance_name}"
        $instance_opt = "-n ${instance_name}"
    }

    $reload_vcl_opts = varnish::reload_vcl_opts($vcl_config['varnish_probe_ms'],
                                                $separate_vcl,
                                                $instance_name,
                                                $vcl)

    # Install VCL include files shared by all instances
    include varnish::common::vcl

    $extra_vcl_variable_to_make_puppet_parser_happy = suffix($extra_vcl, " ${instancesuffix}")
    varnish::wikimedia_vcl { $extra_vcl_variable_to_make_puppet_parser_happy:
        generate_extra_vcl => true,
        vcl_config         => $vcl_config,
        before             => Service["varnish${instancesuffix}"],
    }


    # Raise an icinga critical if the Varnish child process has been started
    # more than once; that means it has died unexpectedly. If the metric has
    # value 1, it means that everything is fine.
    $_hostname = $facts['networking']['hostname']
    $prometheus_labels = "instance=~\"${_hostname}:.*\",layer=\"frontend\""

    monitoring::check_prometheus { 'varnish-frontend-check-child-start':
        description     => 'Varnish frontend child restarted',
        dashboard_links => ["https://grafana.wikimedia.org/d/000000330/varnish-machine-stats?orgId=1&viewPanel=66&var-server=${_hostname}&var-datasource=${::site} prometheus/ops"],
        query           => "scalar(varnish_mgt_child_start{${prometheus_labels}})",
        method          => 'ge',
        warning         => 2,
        critical        => 2,
        prometheus_url  => "http://prometheus.svc.${::site}.wmnet/ops",
        notes_link      => 'https://wikitech.wikimedia.org/wiki/Varnish',
    }

    ([$vcl] + $separate_vcl).each |String $vcl_name| {
        varnish::wikimedia_vcl { "/etc/varnish/wikimedia_${vcl_name}.vcl":
            require                => File["/etc/varnish/${vcl_name}.inc.vcl"],
            template_path          => "${module_name}/wikimedia-frontend.vcl.erb",
            vcl_config             => $vcl_config,
            backend_caches         => $backend_caches,
            backend_options        => $backend_options,
            dynamic_backend_caches => $backends_in_etcd,
            vcl                    => $vcl_name,
            is_separate_vcl        => $vcl_name in $separate_vcl,
            wikimedia_nets         => $wikimedia_nets,
            wikimedia_trust        => $wikimedia_trust,
            wikimedia_domains      => $wikimedia_domains,
            wmcs_domains           => $wmcs_domains,
        }

        # This version of wikimedia_${vcl_name}.vcl is exactly the same as the
        # one under /etc/varnish but without any backends defined. The goal is
        # to make it possible to run the VTC test files under
        # /usr/share/varnish/tests without having to modify any VCL file by
        # hand.
        varnish::wikimedia_vcl { "/usr/share/varnish/tests/wikimedia_${vcl_name}.vcl":
            require                => File['/usr/share/varnish/tests'],
            varnish_testing        => true,
            template_path          => "${module_name}/wikimedia-frontend.vcl.erb",
            vcl_config             => $vcl_config,
            backend_caches         => $backend_caches,
            backend_options        => $backend_options,
            dynamic_backend_caches => false,
            vcl                    => $vcl_name,
            is_separate_vcl        => $vcl_name in $separate_vcl,
            wikimedia_nets         => $wikimedia_nets,
            wikimedia_trust        => $wikimedia_trust,
            wikimedia_domains      => $wikimedia_domains,
            wmcs_domains           => $wmcs_domains,
        }

        varnish::wikimedia_vcl { "/etc/varnish/${vcl_name}.inc.vcl":
            template_path          => "varnish/${vcl_name}.inc.vcl.erb",
            notify                 => Exec["load-new-vcl-file${instancesuffix}"],
            vcl_config             => $vcl_config,
            backend_caches         => $backend_caches,
            backend_options        => $backend_options,
            dynamic_backend_caches => $backends_in_etcd,
            wikimedia_domains      => $wikimedia_domains,
            wmcs_domains           => $wmcs_domains,
        }

        varnish::wikimedia_vcl { "/usr/share/varnish/tests/${vcl_name}.inc.vcl":
            require                => File['/usr/share/varnish/tests'],
            varnish_testing        => true,
            template_path          => "varnish/${vcl_name}.inc.vcl.erb",
            vcl_config             => $vcl_config,
            backend_caches         => $backend_caches,
            backend_options        => $backend_options,
            dynamic_backend_caches => false,
            wikimedia_domains      => $wikimedia_domains,
            wmcs_domains           => $wmcs_domains,
        }
    }

    # varnish frontend needs CAP_NET_BIND_SERVICE as it binds to port 80
    $capabilities = 'CAP_SETUID CAP_SETGID CAP_CHOWN CAP_NET_BIND_SERVICE CAP_KILL CAP_DAC_OVERRIDE'

    # Array of VCL files required by Varnish systemd::service.
    # load-new-vcl-file below subscribes to these too, reload-vcl needs to be
    # run when they change.
    $vcl_files = [
        "/etc/varnish/${vcl}.inc.vcl",
        "/etc/varnish/wikimedia_${vcl}.vcl",
        suffix(prefix($extra_vcl, '/etc/varnish/'),'.inc.vcl'),
    ] + $separate_vcl.map |$vcl_name| {
        "/etc/varnish/wikimedia_${vcl_name}.vcl"
    }

    $enable_geoiplookup = $vcl == 'text-frontend'

    systemd::service { "varnish${instancesuffix}":
        content        => systemd_template('varnish'),
        service_params => {
            tag     => 'varnish_instance',
            enable  => true,
            require => [
                Package['varnish'],
                Mount['/var/lib/varnish'],
                File[$vcl_files],
            ],
        },
    }

    systemd::service { "varnish${instancesuffix}-slowlog":
        ensure         => present,
        content        => systemd_template('varnishslowlog'),
        restart        => true,
        service_params => {
            require => Service["varnish${instancesuffix}"],
            enable  => true,
        },
        require        => File['/usr/local/bin/varnishslowlog'],
        subscribe      => File[
            '/usr/local/bin/varnishslowlog',
            "/usr/local/lib/python${varnish::common::python_version}/dist-packages/wikimedia_varnishlogconsumer.py",
        ],
    }

    profile::auto_restarts::service { "varnish${instancesuffix}-slowlog": }

    systemd::service { "varnish${instancesuffix}-hospital":
        ensure         => present,
        content        => systemd_template('varnishospital'),
        restart        => true,
        service_params => {
            require => Service["varnish${instancesuffix}"],
            enable  => true,
        },
        subscribe      => File[
            '/usr/local/bin/varnishospital',
            "/usr/local/lib/python${varnish::common::python_version}/dist-packages/wikimedia_varnishlogconsumer.py",
        ],
    }

    profile::auto_restarts::service { "varnish${instancesuffix}-hospital": }

    systemd::service { "varnish${instancesuffix}-fetcherr":
        ensure         => present,
        content        => systemd_template('varnishfetcherr'),
        restart        => true,
        service_params => {
            require => Service["varnish${instancesuffix}"],
            enable  => true,
        },
        subscribe      => File[
            '/usr/local/bin/varnishfetcherr',
            "/usr/local/lib/python${varnish::common::python_version}/dist-packages/wikimedia_varnishlogconsumer.py",
        ],
    }

    profile::auto_restarts::service { "varnish${instancesuffix}-fetcherr": }

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
                File[$vcl_files],
            ],
        command     => "/usr/local/sbin/reload-vcl ${reload_vcl_opts} || (touch ${vcl_failed_file}; false)",
        unless      => "test -f ${vcl_failed_file}",
        path        => '/bin:/usr/bin',
        refreshonly => true,
    }

    exec { "retry-load-new-vcl-file${instancesuffix}":
        require => Exec["load-new-vcl-file${instancesuffix}"],
        command => "/usr/local/sbin/reload-vcl ${reload_vcl_opts} && (rm ${vcl_failed_file}; true)",
        onlyif  => "test -f ${vcl_failed_file}",
        path    => '/bin:/usr/bin',
    }

    # TODO/puppet4: convert this to be a define that uses instance name as title and ports as a parameter
    # to allow having non-strigified port numbers.
    varnish::monitoring::instance { $ports.map |$port| { String($port) }:
        instance => $title,
    }

    if $listen_uds {
        $listen_uds.each |Stdlib::Unixpath $uds_path| {
            nrpe::monitor_service { "check-varnish-uds${instancesuffix}-${uds_path}":
                ensure       => present,
                description  => "Check Varnish UDS ${uds_path}",
                nrpe_command => "/usr/local/lib/nagios/plugins/check_varnish_uds --socket ${uds_path}",
                sudo_user    => 'root',
                notes_url    => 'https://wikitech.wikimedia.org/wiki/Varnish',
                require      => File['/usr/local/lib/nagios/plugins/check_varnish_uds'],
            }
        }
    }

}
