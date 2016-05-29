class role::cache::maps {
    include role::cache::2layer
    include role::cache::ssl::unified
    if $::standard::has_ganglia {
        include varnish::monitoring::ganglia::vhtcpd
    }

    class { 'varnish::htcppurger':
        mc_addrs => [ '239.128.0.114' ],
    }

    class { 'lvs::realserver':
        realserver_ips => $lvs::configuration::service_ips['maps'][$::site],
    }

    $fe_cache_be_opts = {
        'port'                  => 3128,
        'connect_timeout'       => '5s',
        'first_byte_timeout'    => '35s',
        'max_connections'       => 100000,
        'probe'                 => 'varnish',
    }

    $be_cache_be_opts = {
        'port'                  => 3128,
        'connect_timeout'       => '5s',
        'first_byte_timeout'    => '35s',
        'max_connections'       => 1000,
        'probe'                 => 'varnish',
    }

    $apps = hiera('cache::maps::apps')
    $app_directors = {
        'kartotherian'   => {
            'dynamic'  => 'no',
            'type'     => 'random',
            'backends' => $apps['kartotherian']['backends'][$apps['kartotherian']['route']],
            'be_opts' => {
                'port'                  => 6533,
                'connect_timeout'       => '5s',
                'first_byte_timeout'    => '35s',
                'max_connections'       => 1000,
            },
        },
    }

    $common_vcl_config = {
        'cache4xx'         => '1m',
        'purge_host_regex' => $::role::cache::base::purge_host_not_upload_re,
        'ttl_cap'          => '1d',
        'pass_random'      => true,
    }

    role::cache::instances { 'maps':
        fe_mem_gb        => ceiling(0.5 * $::memorysize_mb / 1024.0),
        fe_jemalloc_conf => 'lg_dirty_mult:8,lg_chunk_size:17',
        runtime_params   => ['default_ttl=86400'],
        app_directors    => $app_directors,
        app_be_opts      => [],
        fe_vcl_config    => $common_vcl_config,
        be_vcl_config    => $common_vcl_config,
        fe_extra_vcl     => [],
        be_extra_vcl     => [],
        be_storage       => $::role::cache::2layer::persistent_storage_args,
        fe_cache_be_opts => $fe_cache_be_opts,
        be_cache_be_opts => $be_cache_be_opts,
        cluster_nodes    => hiera('cache::maps::nodes'),
    }
}
