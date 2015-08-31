class role::cache::maps {
    system::role { 'role::cache::maps':
        description => 'maps Varnish cache server',
    }

    class { 'varnish::htcppurger': varnish_instances => [ '127.0.0.1:80', '127.0.0.1:3128' ] }

    include role::cache::2layer

    class { 'lvs::realserver':
        realserver_ips => $lvs::configuration::service_ips['maps'][$::site],
    }

    $maps_nodes = hiera('cache::maps::nodes')
    $site_maps_nodes = $maps_nodes[$::site]

    $memory_storage_size = 12

    include role::cache::ssl::unified

    $varnish_be_directors = {
        'one' => {
            'backend'   => {
                'dynamic'  => 'no',
                'type'     => 'random',
                # XXX note explicit abnormal hack: cache only exists in eqiad, service only exists in codfw...
                'backends' => $role::cache::configuration::backends[$::realm]['kartotherian']['codfw'],
            },
        },
        # XXX maps has no tier-2, yet
    }

    if $::role::cache::configuration::has_ganglia {
        include varnish::monitoring::ganglia::vhtcpd
    }

    $common_vcl_config = {
        'cache4xx'         => '1m',
        'purge_host_regex' => $::role::cache::base::purge_host_not_upload_re,
    }

    $be_vcl_config = merge($common_vcl_config, {
        'layer'            => 'backend',
    })

    $fe_vcl_config = merge($common_vcl_config, {
        'layer'            => 'frontend',
        'retry503'         => 1,
        'https_redirects'  => true,
    })

    varnish::instance { 'maps-backend':
        name               => '',
        vcl                => 'maps-backend',
        port               => 3128,
        admin_port         => 6083,
        runtime_parameters => ['default_ttl=86400'],
        storage            => $::role::cache::2layer::persistent_storage_args,
        directors          => $varnish_be_directors[$::site_tier],
        vcl_config         => $be_vcl_config,
        backend_options    => array_concat($::role::cache::2layer::backend_scaled_weights, [
            {
                'backend_match' => '^cp[0-9]+\.eqiad.wmnet$',
                'port'          => 3128,
                'probe'         => 'varnish',
            },
            {
                'port'                  => 4000,
                'connect_timeout'       => '5s',
                'first_byte_timeout'    => '35s',
                'between_bytes_timeout' => '4s',
                'max_connections'       => 1000,
                'probe'                 => 'maps',
            },
        ]),
    }

    varnish::instance { 'maps-frontend':
        name               => 'frontend',
        vcl                => 'maps-frontend',
        port               => 80,
        admin_port         => 6082,
        runtime_parameters => ['default_ttl=86400'],
        storage            => "-s malloc,${memory_storage_size}G",
        directors          => {
            'backend' => {
                'dynamic'  => 'yes',
                'type'     => 'chash',
                'backends' => $site_maps_nodes,
            },
        },
        vcl_config         => $fe_vcl_config,
        backend_options    => array_concat($::role::cache::2layer::backend_scaled_weights, [
            {
                'port'                  => 3128,
                'connect_timeout'       => '5s',
                'first_byte_timeout'    => '35s',
                'between_bytes_timeout' => '2s',
                'max_connections'       => 100000,
                'probe'                 => 'varnish',
            },
        ]),
    }

    include role::cache::logging

    # ToDo: Remove production conditional once this works
    # is verified to work in labs.
    if $::realm == 'production' {
        # Install a varnishkafka producer to send
        # varnish webrequest logs to Kafka.
        class { 'role::cache::kafka::webrequest':
            topic => 'webrequest_maps',
        }
    }
}
