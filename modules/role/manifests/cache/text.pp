class role::cache::text {
    include role::cache::2layer

    $text_nodes = hiera('cache::text::nodes')
    $site_text_nodes = $text_nodes[$::site]

    # 1/8 of total mem
    $memory_storage_size = ceiling(0.125 * $::memorysize_mb / 1024.0)

    system::role { 'role::cache::text':
        description => 'text Varnish cache server',
    }

    if $::realm == 'production' {
        include role::cache::ssl::sni
    }

    require geoip
    require geoip::dev # for VCL compilation using libGeoIP

    class { 'lvs::realserver':
        realserver_ips => $lvs::configuration::lvs_service_ips[$::realm]['text'][$::site],
    }

    $varnish_be_directors = {
        'one' => {
            'backend'           => $role::cache::configuration::backends[$::realm]['appservers'][$::mw_primary],
            'api'               => $role::cache::configuration::backends[$::realm]['api'][$::mw_primary],
            'rendering'         => $role::cache::configuration::backends[$::realm]['rendering'][$::mw_primary],
            'test_wikipedia'    => $role::cache::configuration::backends[$::realm]['test_appservers'][$::mw_primary],
        },
        'two' => {
            'eqiad' => $text_nodes['eqiad'],
        },
    }

    include standard
    include nrpe

    #class { "varnish::packages": version => "3.0.3plus~rc1-wm13" }

    class { 'varnish::htcppurger':
        varnish_instances => [ '127.0.0.1:80', '127.0.0.1:3128' ],
    }

    if $::role::cache::configuration::has_ganglia {
        include varnish::monitoring::ganglia::vhtcpd
    }

    $runtime_params = $::site ? {
        #'esams' => ['prefer_ipv6=on','default_ttl=2592000'],
        default => ['default_ttl=2592000'],
    }

    $director_type_cluster = $::role::cache::base::cluster_tier ? {
        'one'   => 'random',
        default => 'chash',
    }

    varnish::instance { 'text-backend':
        name               => '',
        vcl                => 'text-backend',
        extra_vcl          => ['text-common'],
        port               => 3128,
        admin_port         => 6083,
        runtime_parameters => $runtime_params,
        storage            => $::role::cache::2layer::persistent_storage_args,
        directors          => $varnish_be_directors[$::role::cache::base::cluster_tier],
        director_type      => $director_type_cluster,
        vcl_config         => {
            'default_backend'  => $::role::cache::base::default_backend,
            'retry503'         => 1,
            'retry5xx'         => 0,
            'cache4xx'         => '1m',
            'purge_host_regex' => $::role::cache::base::purge_host_not_upload_re,
            'cluster_tier'     => $::role::cache::base::cluster_tier,
            'layer'            => 'backend',
            'ssl_proxies'      => $::role::cache::base::wikimedia_networks,
        },
        backend_options    => array_concat($::role::cache::2layer::backend_scaled_weights, [
            {
                'backend_match' => '^cp[0-9]+\.eqiad\.wmnet$',
                'port'          => 3128,
                'probe'         => 'varnish',
            },
            {
                'backend_match'   => '^mw1017\.eqiad\.wmnet$',
                'max_connections' => 20,
            },
            {
                'port'                  => 80,
                'connect_timeout'       => '5s',
                'first_byte_timeout'    => '180s',
                'between_bytes_timeout' => '4s',
                'max_connections'       => 1000,
            },
        ]),
        wikimedia_networks => $::role::cache::base::wikimedia_networks,
    }

    varnish::instance { 'text-frontend':
        name            => 'frontend',
        vcl             => 'text-frontend',
        extra_vcl       => ['text-common'],
        port            => 80,
        admin_port      => 6082,
        storage         => "-s malloc,${memory_storage_size}G",
        directors       => {
            'backend' => $site_text_nodes,
        },
        director_type   => 'chash',
        vcl_config      => {
            'retry503'         => 1,
            'retry5xx'         => 0,
            'cache4xx'         => '1m',
            'purge_host_regex' => $::role::cache::base::purge_host_not_upload_re,
            'cluster_tier'     => $::role::cache::base::cluster_tier,
            'layer'            => 'frontend',
            'ssl_proxies'      => $::role::cache::base::wikimedia_networks,
        },
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
        cluster_options => {
            'enable_geoiplookup' => true,
        },
    }

    include role::cache::logging

    # HTCP packet loss monitoring on the ganglia aggregators
    if $ganglia_aggregator and $::site != 'esams' {
        include misc::monitoring::htcp-loss
    }

    # ToDo: Remove production conditional once this works
    # is verified to work in labs.
    if $::realm == 'production' {
        # Install a varnishkafka producer to send
        # varnish webrequest logs to Kafka.
        class { 'role::cache::kafka::webrequest':
            topic => 'webrequest_text',
        }
    }
}
