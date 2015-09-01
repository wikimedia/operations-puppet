class role::cache::mobile {
    system::role { 'role::cache::mobile':
        description => 'mobile Varnish cache server',
    }

    class { 'varnish::htcppurger': varnish_instances => [ '127.0.0.1:80', '127.0.0.1:3128' ] }

    include role::cache::2layer

    class { 'lvs::realserver':
        realserver_ips => $lvs::configuration::service_ips['mobile'][$::site],
    }

    $mobile_nodes = hiera('cache::mobile::nodes')
    $site_mobile_nodes = $mobile_nodes[$::site]

    # 1/8 of total mem
    $memory_storage_size = ceiling(0.125 * $::memorysize_mb / 1024.0)

    include role::cache::ssl::unified

    require geoip
    require geoip::dev # for VCL compilation using libGeoIP

    $varnish_be_directors = {
        'one' => {
            'backend'        => {
                'dynamic'  => 'no',
                'type'     => 'random',
                'backends' => $role::cache::configuration::backends[$::realm]['appservers'][$::mw_primary],
            },
            'api'            => {
                'dynamic'  => 'no',
                'type'     => 'random',
                'backends' => $role::cache::configuration::backends[$::realm]['api'][$::mw_primary],
            },
            'rendering'        => {
                'dynamic'  => 'no',
                'type'     => 'random',
                'backends' => $role::cache::configuration::backends[$::realm]['rendering'][$::mw_primary],
            },
            'security_audit'   => {
                'dynamic'  => 'no',
                'type'     => 'random',
                'backends' => $role::cache::configuration::backends[$::realm]['security_audit'][$::mw_primary],
            },
            'test_wikipedia' => {
                'dynamic'  => 'no',
                'type'     => 'random',
                'backends' => $role::cache::configuration::backends[$::realm]['test_appservers'][$::mw_primary],
            },
            'restbase_backend' => {
                'dynamic'  => 'no',
                'type'     => 'random',
                'backends' => $role::cache::configuration::backends[$::realm]['restbase'][$::mw_primary],
            },
        },
        'two' => {
            'backend' => {
                'dynamic'  => 'yes',
                'type'     => 'chash',
                'backends' => $mobile_nodes['eqiad'],
            },
            'backend_random' => {
                'dynamic'  => 'yes',
                'type'     => 'random',
                'backends' => $mobile_nodes['eqiad'],
                'service'  => 'varnish-be-rand',
            },
        }
    }

    if $::role::cache::configuration::has_ganglia {
        include varnish::monitoring::ganglia::vhtcpd
    }

    $common_vcl_config = {
        'purge_host_regex'   => $::role::cache::base::purge_host_not_upload_re,
        'static_host'        => $::role::cache::base::static_host,
        'do_gzip'            => true,
    }

    $be_vcl_config = merge($common_vcl_config, {
        'layer'              => 'backend',
    })

    $fe_vcl_config = merge($common_vcl_config, {
        'layer'              => 'frontend',
        'retry503'           => 1,
        'enable_geoiplookup' => true,
        'https_redirects'    => true,
    })

    class { 'varnish::zero_update':
        site         => $::role::cache::base::zero_site,
        auth_content => secret('misc/zerofetcher.auth'),
    }

    varnish::instance { 'mobile-backend':
        name               => '',
        vcl                => 'mobile-backend',
        extra_vcl          => ['text-common'],
        port               => 3128,
        admin_port         => 6083,
        storage            => $::role::cache::2layer::persistent_storage_args,
        runtime_parameters => ['default_ttl=2592000'],
        directors          => $varnish_be_directors[$::site_tier],
        vcl_config         => $be_vcl_config,
        backend_options    => array_concat($::role::cache::2layer::backend_scaled_weights, [
            {
                'backend_match'   => '^mw1017\.eqiad\.wmnet$',
                'max_connections' => 20,
            },
            {
                'backend_match' => '^cp[0-9]+\.eqiad\.wmnet$',
                'port'          => 3128,
                'probe'         => 'varnish',
            },
            {
                'backend_match'   => '^restbase\.svc\.|^deployment-restbase',
                'port'            => 7231,
                'max_connections' => 5000,
            },
            {
                'port'                  => 80,
                'connect_timeout'       => '5s',
                'first_byte_timeout'    => '180s',
                'between_bytes_timeout' => '4s',
                'max_connections'       => 600,
            },
        ]),
    }

    varnish::instance { 'mobile-frontend':
        name               => 'frontend',
        vcl                => 'mobile-frontend',
        extra_vcl          => ['text-common', 'zero'],
        port               => 80,
        admin_port         => 6082,
        storage            => "-s malloc,${memory_storage_size}G",
        runtime_parameters => ['default_ttl=2592000'],
        directors          => {
            'backend' => {
                'dynamic'  => 'yes',
                'type'     => 'chash',
                'backends' => $site_mobile_nodes,
            },
            'backend_random' => {
                'dynamic'  => 'yes',
                'type'     => 'random',
                'backends' => $site_mobile_nodes,
                'service'  => 'varnish-be-rand',
            },
        },
        vcl_config         => $fe_vcl_config,
        backend_options    => array_concat($::role::cache::2layer::backend_scaled_weights, [
            {
                'port'                  => 3128,
                'connect_timeout'       => '5s',
                'first_byte_timeout'    => '185s',
                'between_bytes_timeout' => '2s',
                'max_connections'       => 100000,
                'probe'                 => 'varnish',
            },
        ]),
    }

    # varnish::logging to be removed once
    # udp2log kafka consumer is implemented and deployed.
    include role::cache::logging

    class { '::role::cache::kafka::statsv':
        varnish_name => 'frontend',
    }

    # role::cache::logging::eventlistener will soon be fully
    # replaced by role::cache::kafka::eventlogging.
    class { '::role::cache::logging::eventlistener':
        instance_name => 'frontend',
    }
    class { '::role::cache::kafka::eventlogging':
        varnish_name => 'frontend',
    }

    # ToDo: Remove production conditional once this works
    # is verified to work in labs.
    if $::realm == 'production' {
        # Install a varnishkafka producer to send
        # varnish webrequest logs to Kafka.
        class { 'role::cache::kafka::webrequest': topic => 'webrequest_mobile' }
    }
}
