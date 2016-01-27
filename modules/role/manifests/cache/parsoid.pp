class role::cache::parsoid {
    system::role { 'role::cache::parsoid':
        description => 'Parsoid Varnish cache server',
    }

    # Monitor TCP Connection States
    diamond::collector { 'TcpConnStates':
        source => 'puppet:///modules/diamond/collector/tcpconnstates.py',
    }

    include role::cache::2layer

    class { 'lvs::realserver':
        realserver_ips => $lvs::configuration::service_ips['parsoidcache'][$::site],
    }

    $cluster_nodes = hiera('cache::parsoid::nodes')
    $site_cluster_nodes = $cluster_nodes[$::site]

    include role::cache::ssl::unified

    $common_vcl_config = {
        'purge_host_regex' => $::role::cache::base::purge_host_not_upload_re,
    }

    $be_vcl_config = merge($common_vcl_config, {
        'layer'            => 'backend',
    })

    $fe_vcl_config = merge($common_vcl_config, {
        'layer'            => 'frontend',
    })

    varnish::instance { 'parsoid-backend':
        name             => '',
        vcl              => 'parsoid-backend',
        extra_vcl        => ['parsoid-common'],
        ports            => [ 3128 ],
        admin_port       => 6083,
        storage          => $::role::cache::2layer::persistent_storage_args,
        directors        => {
            'backend' => {
                'dynamic'  => 'no',
                'type'     => 'hash', # probably wrong, but current value before this commit! XXX
                'backends' => $::role::cache::configuration::backends[$::realm]['parsoid'][$::mw_primary],
            }
        },
        vcl_config       => $be_vcl_config,
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
        ports           => [ 80 ],
        admin_port      => 6082,
        directors       => {
            'backend'          => {
                'dynamic'  => 'yes',
                'type'     => 'chash',
                'backends' => $site_cluster_nodes,
            },
            'cxserver_backend' => {
                'dynamic'  => 'no',
                'type'     => 'chash', # probably wrong, but current value before this commit! XXX
                'backends' => $::role::cache::configuration::backends[$::realm]['cxserver'][$::mw_primary],
            },
            'citoid_backend'   => {
                'dynamic'  => 'no',
                'type'     => 'chash', # probably wrong, but current value before this commit! XXX
                'backends' => $::role::cache::configuration::backends[$::realm]['citoid'][$::mw_primary],
            },
            'restbase_backend' => {
                'dynamic'  => 'no',
                'type'     => 'chash', # probably wrong, but current value before this commit! XXX
                'backends' => $::role::cache::configuration::backends[$::realm]['restbase'][$::mw_primary],
            },
        },
        vcl_config      => $fe_vcl_config,
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

    # Parse varnishlogs for request statistics and send to statsd.
    varnish::logging::reqstats { 'frontend':
        metric_prefix => "varnish.${::site}.parsoid.frontend.request",
        statsd        => hiera('statsd'),
    }
}
