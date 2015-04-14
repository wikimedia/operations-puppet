class role::cache::upload inherits role::cache::2layer {

    $upload_nodes = hiera('::cache::upload::nodes', {})
    $local_upload_nodes = $upload_nodes[$::site]

    if $::realm == 'production' {
        $memory_storage_size = floor((0.083 * $::memorysize_mb / 1024.0) + 0.5) # 1/12 of total mem
    }
    else {
        $memory_storage_size = 1
    }

    system::role { 'role::cache::upload':
        description => 'upload Varnish cache server',
    }

    if $::realm == 'production' {
        include role::cache::ssl::sni
    }

    class { 'lvs::realserver':
        realserver_ips => $lvs::configuration::lvs_service_ips[$::realm]['upload'][$::site],
    }

    $varnish_be_directors = {
        1 => {
            'backend'   => $lvs::configuration::lvs_service_ips[$::realm]['swift'][$::mw_primary],
            'rendering' => $role::cache::configuration::backends[$::realm]['rendering'][$::mw_primary],
        },
        2 => {
            'eqiad' => $upload_nodes['eqiad']
        }
    }

    $default_backend = $cluster_tier ? {
        1       => 'backend',
        default => 'eqiad',
    }

    if $cluster_tier == 1 {
        $director_retries = 2
    } else {
        $director_retries = $backend_weight_avg * 4
    }

    include standard
    include nrpe

    $storage_partitions = $::realm ? {
        'production' => ['sda3', 'sdb3'],
        'labs' => ['vdb']
    }
    varnish::setup_filesystem{ $storage_partitions:
        before => Varnish::Instance['upload-backend'],
    }

    class { 'varnish::htcppurger':
        varnish_instances => [ '127.0.0.1:80', '127.0.0.1:3128' ],
    }

    if $::role::cache::configuration::has_ganglia {
        include varnish::monitoring::ganglia::vhtcpd
    }

    # lint:ignore:case_without_default
    case $::realm {
    # lint:endignore
        'production': {
            $cluster_options = {
                'upload_domain' => 'upload.wikimedia.org',
                'top_domain'    => 'org',
                'do_gzip'       => true,
            }
        }
        'labs': {
            $cluster_options = {
                'upload_domain' => 'upload.beta.wmflabs.org',
                'top_domain'    => 'beta.wmflabs.org',
                'do_gzip'       => true,
            }
        }
    }

    $runtime_params = $::site ? {
        #'esams' => ['prefer_ipv6=on','default_ttl=2592000'],
        default  => ['default_ttl=2592000'],
    }


    $storage_size_bigobj = floor($storage_size_main / 6)
    $storage_size_up = $storage_size_main - $storage_size_bigobj
    $storage_conf =  $::realm ? {
        'production' => "-s main1=persistent,/srv/sda3/varnish.main1,${storage_size_up}G,$mma0 -s main2=persistent,/srv/sdb3/varnish.main2,${storage_size_up}G,$mma1 -s bigobj1=file,/srv/sda3/varnish.bigobj1,${storage_size_bigobj}G -s bigobj2=file,/srv/sdb3/varnish.bigobj2,${storage_size_bigobj}G",
        'labs'       => "-s main1=persistent,/srv/vdb/varnish.main1,${storage_size_up}G,$mma0 -s main2=persistent,/srv/vdb/varnish.main2,${storage_size_up}G,$mma1 -s bigobj1=file,/srv/vdb/varnish.bigobj1,${storage_size_bigobj}G -s bigobj2=file,/srv/vdb/varnish.bigobj2,${storage_size_bigobj}G"
    }

    $director_type_cluster = $cluster_tier ? {
        1       => 'random',
        default => 'chash',
    }

    varnish::instance { 'upload-backend':
        name               => '',
        vcl                => 'upload-backend',
        port               => 3128,
        admin_port         => 6083,
        runtime_parameters => $runtime_params,
        storage            => $storage_conf,
        directors          => $varnish_be_directors[$cluster_tier],
        director_type      => $director_type_cluster,
        director_options   => {
            'retries' => $director_retries,
        },
        vcl_config         => {
            'default_backend'  => $default_backend,
            'retry5xx'         => 0,
            'cache4xx'         => '1m',
            'purge_host_regex' => $purge_host_only_upload_re,
            'cluster_tier'     => $cluster_tier,
            'layer'            => 'backend',
            'ssl_proxies'      => $wikimedia_networks,
        },
        backend_options    => array_concat($backend_scaled_weights, [
            {
                'backend_match' => '^cp[0-9]+\.eqiad.wmnet$',
                'port'          => 3128,
                'probe'         => 'varnish',
            },
            {
                'port'                  => 80,
                'connect_timeout'       => '5s',
                'first_byte_timeout'    => '35s',
                'between_bytes_timeout' => '4s',
                'max_connections'       => 1000,
            },
        ]),
        cluster_options    => $cluster_options,
        wikimedia_networks => $wikimedia_networks,
    }

    varnish::instance { 'upload-frontend':
        name            => 'frontend',
        vcl             => 'upload-frontend',
        port            => 80,
        admin_port      => 6082,
        storage         => "-s malloc,${memory_storage_size}G",
        directors       => {
            'backend' => $local_upload_nodes,
        },
        director_type   => 'chash',
        vcl_config      => {
            'retry5xx'         => 0,
            'cache4xx'         => '1m',
            'purge_host_regex' => $purge_host_only_upload_re,
            'cluster_tier'     => $cluster_tier,
            'layer'            => 'frontend',
            'ssl_proxies'      => $wikimedia_networks,
        },
        backend_options => array_concat($backend_scaled_weights, [
            {
                'port'                  => 3128,
                'connect_timeout'       => '5s',
                'first_byte_timeout'    => '35s',
                'between_bytes_timeout' => '2s',
                'max_connections'       => 100000,
                'probe'                 => 'varnish',
            },
        ]),
        cluster_options => $cluster_options,
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
            topic => 'webrequest_upload',
        }
    }
}
