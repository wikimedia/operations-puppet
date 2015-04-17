class role::cache::upload {
    include role::cache::2layer

    $upload_nodes = hiera('cache::upload::nodes')
    $site_upload_nodes = $upload_nodes[$::site]

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
        'one' => {
            'backend'   => $lvs::configuration::lvs_service_ips[$::realm]['swift'][$::mw_primary],
            'rendering' => $role::cache::configuration::backends[$::realm]['rendering'][$::mw_primary],
        },
        'two' => {
            'eqiad' => $upload_nodes['eqiad'],
        }
    }

    if $::role::cache::base::cluster_tier == 'one' {
        $director_retries = 2
    } else {
        $director_retries = $::role::cache::2layer::backend_weight_avg * 4
    }

    include standard
    include nrpe

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

    $storage_size_bigobj = floor($::role::cache::2layer::storage_size / 6)
    $storage_size_up = $::role::cache::2layer::storage_size - $storage_size_bigobj
    $upload_storage_args = join([
        "-s main1=persistent,/srv/${::role::cache::2layer::storage_parts[0]}/varnish.main1,${storage_size_up}G,${::role::cache::2layer::mma[0]}",
        "-s main2=persistent,/srv/${::role::cache::2layer::storage_parts[1]}/varnish.main2,${storage_size_up}G,${::role::cache::2layer::mma[1]}",
        "-s bigobj1=file,/srv/${::role::cache::2layer::storage_parts[0]}/varnish.bigobj1,${storage_size_bigobj}G",
        "-s bigobj2=file,/srv/${::role::cache::2layer::storage_parts[1]}/varnish.bigobj2,${storage_size_bigobj}G",
    ], ' ')

    $director_type_cluster = $::role::cache::base::cluster_tier ? {
        'one'   => 'random',
        default => 'chash',
    }

    varnish::instance { 'upload-backend':
        name               => '',
        vcl                => 'upload-backend',
        port               => 3128,
        admin_port         => 6083,
        runtime_parameters => $runtime_params,
        storage            => $upload_storage_args,
        directors          => $varnish_be_directors[$::role::cache::base::cluster_tier],
        director_type      => $director_type_cluster,
        director_options   => {
            'retries' => $director_retries,
        },
        vcl_config         => {
            'default_backend'  => $::role::cache::base::default_backend,
            'retry5xx'         => 0,
            'cache4xx'         => '1m',
            'purge_host_regex' => $::role::cache::base::purge_host_only_upload_re,
            'cluster_tier'     => $::role::cache::base::cluster_tier,
            'layer'            => 'backend',
            'ssl_proxies'      => $::role::cache::base::wikimedia_networks,
        },
        backend_options    => array_concat($::role::cache::2layer::backend_scaled_weights, [
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
        wikimedia_networks => $::role::cache::base::wikimedia_networks,
    }

    varnish::instance { 'upload-frontend':
        name            => 'frontend',
        vcl             => 'upload-frontend',
        port            => 80,
        admin_port      => 6082,
        storage         => "-s malloc,${memory_storage_size}G",
        directors       => {
            'backend' => $site_upload_nodes,
        },
        director_type   => 'chash',
        vcl_config      => {
            'retry5xx'         => 0,
            'cache4xx'         => '1m',
            'purge_host_regex' => $::role::cache::base::purge_host_only_upload_re,
            'cluster_tier'     => $::role::cache::base::cluster_tier,
            'layer'            => 'frontend',
            'ssl_proxies'      => $::role::cache::base::wikimedia_networks,
        },
        backend_options => array_concat($::role::cache::2layer::backend_scaled_weights, [
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
