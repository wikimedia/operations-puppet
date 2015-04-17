class role::cache::parsoid {
    include role::cache::2layer

    $parsoid_nodes = hiera('cache::parsoid::nodes')
    $site_parsoid_nodes = $parsoid_nodes[$::site]

    if ( $::realm == 'production' ) {
        include role::cache::ssl::parsoid
    }

    class { 'lvs::realserver':
        realserver_ips => $lvs::configuration::lvs_service_ips[$::realm]['parsoidcache'][$::site],
    }

    system::role { 'role::cache::parsoid':
        description => 'Parsoid Varnish cache server',
    }

    include standard
    include nrpe

    # No HTCP daemon for Parsoid; the MediaWiki extension sends PURGE requests itself
    #class { "varnish::htcppurger": varnish_instances => [ "localhost:80", "localhost:3128" ] }

    varnish::instance { 'parsoid-backend':
        name             => '',
        vcl              => 'parsoid-backend',
        extra_vcl        => ['parsoid-common'],
        port             => 3128,
        admin_port       => 6083,
        storage          => $::role::cache::2layer::persistent_storage_args,
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
            'ssl_proxies' => $::role::cache::base::wikimedia_networks,
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
            'backend'          => $site_parsoid_nodes,
            'cxserver_backend' => $::role::cache::configuration::backends[$::realm]['cxserver'][$::site],
            'citoid_backend'   => $::role::cache::configuration::backends[$::realm]['citoid'][$::site],
            'restbase_backend' => $::role::cache::configuration::backends[$::realm]['restbase'][$::site],
        },
        director_type   => 'chash',
        director_options => {
            'retries' => $::role::cache::2layer::backend_weight_avg * size($site_parsoid_nodes),
        },
        vcl_config      => {
            'retry5xx'    => 0,
            'ssl_proxies' => $::role::cache::base::wikimedia_networks,
        },
        backend_options => array_concat($::role::cache::2layer::backend_scaled_weights, [
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
