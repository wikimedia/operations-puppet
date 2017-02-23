class role::cache::maps {
    include role::cache::base
    include role::cache::ssl::unified
    include ::standard

    class { 'prometheus::node_vhtcpd': }

    class { 'varnish::htcppurger':
        mc_addrs => [ '239.128.0.114' ],
    }

    class { '::lvs::realserver':
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

    $app_def_be_opts = {
        'port'                  => 6533,
        'connect_timeout'       => '5s',
        'first_byte_timeout'    => '35s',
        'max_connections'       => 1000,
    }

    $apps = hiera('cache::maps::apps')
    $app_directors = {
        'kartotherian'   => {
            'backend' => $apps['kartotherian']['backends'][$apps['kartotherian']['route']],
        },
    }

    $common_vcl_config = {
        'purge_host_regex' => $::role::cache::base::purge_host_not_upload_re,
        'ttl_cap'          => '1d',
        'pass_random'      => true,
    }

    $common_runtime_params = ['default_ttl=86400']

    role::cache::instances { 'maps':
        fe_mem_gb         => ceiling(0.4 * $::memorysize_mb / 1024.0),
        fe_jemalloc_conf  => 'lg_dirty_mult:8,lg_chunk:17',
        fe_runtime_params => $common_runtime_params,
        be_runtime_params => $common_runtime_params,
        app_directors     => $app_directors,
        app_def_be_opts   => $app_def_be_opts,
        fe_vcl_config     => $common_vcl_config,
        be_vcl_config     => $common_vcl_config,
        fe_extra_vcl      => [],
        be_extra_vcl      => [],
        be_storage        => $::role::cache::base::file_storage_args,
        fe_cache_be_opts  => $fe_cache_be_opts,
        be_cache_be_opts  => $be_cache_be_opts,
        cluster_nodes     => hiera('cache::maps::nodes'),
    }
}
