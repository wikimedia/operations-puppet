# Virtual resources for the monitoring server
@monitoring::group { 'cache_text_eqiad': description => 'eqiad text Varnish' }
@monitoring::group { 'cache_text_esams': description => 'esams text Varnish' }
@monitoring::group { 'cache_text_ulsfo': description => 'ulsfo text Varnish' }

class role::cache::text inherits role::cache::2layer {
    if $::realm == 'production' {
        $memory_storage_size = floor((0.125 * $::memorysize_mb / 1024.0) + 0.5) # 1/8 of total mem
    }
    else {
        $memory_storage_size = 1
    }

    system::role { 'role::cache::text':
        description => 'text Varnish cache server',
    }

    if $::realm == 'production' {
        include role::cache::ssl_sni
    }

    require geoip
    require geoip::dev # for VCL compilation using libGeoIP

    class { 'lvs::realserver':
        realserver_ips => $lvs::configuration::lvs_service_ips[$::realm]['text'][$::site],
    }

    $varnish_be_directors = {
        1 => {
            'backend'           => $role::cache::configuration::backends[$::realm]['appservers'][$::mw_primary],
            'api'               => $role::cache::configuration::backends[$::realm]['api'][$::mw_primary],
            'rendering'         => $role::cache::configuration::backends[$::realm]['rendering'][$::mw_primary],
            'test_wikipedia'    => $role::cache::configuration::backends[$::realm]['test_appservers'][$::mw_primary],
        },
        2 => {
            'eqiad' => $role::cache::configuration::active_nodes[$::realm]['text']['eqiad'],
        },
    }

    include standard
    include nrpe

    #class { "varnish::packages": version => "3.0.3plus~rc1-wm13" }

    varnish::setup_filesystem{ $storage_partitions:
        before => Varnish::Instance['text-backend']
    }

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

    $storage_conf = $::realm ? {
        'production' => "-s main1=persistent,/srv/sda3/varnish.main1,${storage_size_main}G,$mma0 -s main2=persistent,/srv/sdb3/varnish.main2,${storage_size_main}G,$mma1",
        'labs'  => "-s main1=persistent,/srv/vdb/varnish.main1,${storage_size_main}G,$mma0 -s main2=persistent,/srv/vdb/varnish.main2,${storage_size_main}G,$mma1",
    }

    $director_type_cluster = $cluster_tier ? {
        1       => 'random',
        default => 'chash',
    }

    varnish::instance { 'text-backend':
        name               => '',
        vcl                => 'text-backend',
        extra_vcl          => ['text-common'],
        port               => 3128,
        admin_port         => 6083,
        runtime_parameters => $runtime_params,
        storage            => $storage_conf,
        directors          => $varnish_be_directors[$cluster_tier],
        director_type      => $director_type_cluster,
        vcl_config         => {
            'default_backend'  => $default_backend,
            'retry503'         => 1,
            'retry5xx'         => 0,
            'cache4xx'         => '1m',
            'purge_host_regex' => $purge_host_not_upload_re,
            'cluster_tier'     => $cluster_tier,
            'layer'            => 'backend',
            'ssl_proxies'      => $wikimedia_networks,
        },
        backend_options    => array_concat($backend_scaled_weights, [
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
        wikimedia_networks => $wikimedia_networks,
    }

    varnish::instance { 'text-frontend':
        name            => 'frontend',
        vcl             => 'text-frontend',
        extra_vcl       => ['text-common'],
        port            => 80,
        admin_port      => 6082,
        storage         => "-s malloc,${memory_storage_size}G",
        directors       => {
            'backend' => $role::cache::configuration::active_nodes[$::realm]['text'][$::site],
        },
        director_type   => 'chash',
        vcl_config      => {
            'retry503'         => 1,
            'retry5xx'         => 0,
            'cache4xx'         => '1m',
            'purge_host_regex' => $purge_host_not_upload_re,
            'cluster_tier'     => $cluster_tier,
            'layer'            => 'frontend',
            'ssl_proxies'      => $wikimedia_networks,
        },
        backend_options    => array_concat($backend_scaled_weights, [
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
