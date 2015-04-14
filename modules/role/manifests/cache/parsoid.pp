class role::cache::parsoid inherits role::cache::2layer {

    $parsoid_nodes = hiera('::cache::parsoid::nodes', {})
    $local_parsoid_nodes = $parsoid_nodes[$::site]

    if ( $::realm == 'production' ) {
        include role::cache::ssl::parsoid
        class { 'lvs::realserver':
            realserver_ips => $lvs::configuration::lvs_service_ips[$::realm]['parsoidcache'][$::site],
        }
    }

    system::role { 'role::cache::parsoid':
        description => 'Parsoid Varnish cache server',
    }

    include standard
    include nrpe

    $storage_partitions = $::realm ? {
        'production' => ['sda3', 'sdb3'],
        'labs'       => ['vdb'],
    }
    varnish::setup_filesystem{ $storage_partitions:
        before => Varnish::Instance['parsoid-backend'],
    }

    # No HTCP daemon for Parsoid; the MediaWiki extension sends PURGE requests itself
    #class { "varnish::htcppurger": varnish_instances => [ "localhost:80", "localhost:3128" ] }

    $storage_conf = $::realm ? {
        'production' => "-s main1=persistent,/srv/sda3/varnish.main1,${storage_size_main}G,$mma0 -s main2=persistent,/srv/sdb3/varnish.main2,${storage_size_main}G,$mma1",
        'labs' => "-s main1=persistent,/srv/vdb/varnish.main1,${storage_size_main}G,$mma0 -s main2=persistent,/srv/vdb/varnish.main2,${storage_size_main}G,$mma1",
    }

    varnish::instance { 'parsoid-backend':
        name             => '',
        vcl              => 'parsoid-backend',
        extra_vcl        => ['parsoid-common'],
        port             => 3128,
        admin_port       => 6083,
        storage          => $storage_conf,
        directors        => {
            'backend'          => $::role::cache::configuration::backends[$::realm]['parsoid'][$::mw_primary],
            'cxserver_backend' => $::role::cache::configuration::backends[$::realm]['cxserver'][$::site],
            'citoid_backend'   => $::role::cache::configuration::backends[$::realm]['citoid'][$::site],
            'restbase_backend' => $::role::cache::configuration::backends[$::realm]['restbase'][$::site],
        },
        director_options => {
            'retries' => 2,
        },
        vcl_config       => {
            'retry5xx'    => 1,
            'ssl_proxies' => $wikimedia_networks,
        },
        backend_options  => [
            {
                'backend_match'         => '^cxserver',
                'port'                  => 8080,
                'probe'                 => false,
            },
            {
                'backend_match'         => '^citoid',
                'port'                  => 1970,
                'probe'                 => false,
            },
            {
                'backend_match'         => '^restbase',
                'port'                  => 7231,
                'probe'                 => false, # TODO: Need probe here
            },
            {
                'port'                  => 8000,
                'connect_timeout'       => '5s',
                'first_byte_timeout'    => '5m',
                'between_bytes_timeout' => '20s',
                'max_connections'       => 10000,
            },
        ],
    }

    varnish::instance { 'parsoid-frontend':
        name            => 'frontend',
        vcl             => 'parsoid-frontend',
        extra_vcl       => ['parsoid-common'],
        port            => 80,
        admin_port      => 6082,
        directors       => {
            'backend'          => $local_parsoid_nodes,
            'cxserver_backend' => $::role::cache::configuration::backends[$::realm]['cxserver'][$::site],
            'citoid_backend'   => $::role::cache::configuration::backends[$::realm]['citoid'][$::site],
            'restbase_backend' => $::role::cache::configuration::backends[$::realm]['restbase'][$::site],
        },
        director_type   => 'chash',
        director_options => {
            'retries' => $backend_weight_avg * size($local_parsoid_nodes),
        },
        vcl_config      => {
            'retry5xx'    => 0,
            'ssl_proxies' => $wikimedia_networks,
        },
        backend_options => array_concat($backend_scaled_weights, [
            {
                'backend_match'         => '^cxserver',
                'port'                  => 8080,
                'probe'                 => false,
            },
            {
                'backend_match'         => '^citoid',
                'port'                  => 1970,
                'probe'                 => false,
            },
            {
                'backend_match'         => '^restbase',
                'port'                  => 7231,
                'probe'                 => false, # TODO: Need probe here
            },
            {
                'port'                  => 3128,
                'connect_timeout'       => '5s',
                'first_byte_timeout'    => '6m',
                'between_bytes_timeout' => '20s',
                'max_connections'       => 100000,
                'probe'                 => 'varnish',
            },
        ]),
    }
}
