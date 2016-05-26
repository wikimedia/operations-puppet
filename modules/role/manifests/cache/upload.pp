class role::cache::upload {
    include role::cache::2layer
    include role::cache::ssl::unified
    if $::standard::has_ganglia {
        include varnish::monitoring::ganglia::vhtcpd
    }

    class { 'varnish::htcppurger':
        mc_addrs => [ '239.128.0.112', '239.128.0.113' ],
    }

    class { 'lvs::realserver':
        realserver_ips => $lvs::configuration::service_ips['upload'][$::site],
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

    $apps = hiera('cache::upload::apps')
    $app_directors = {
        'swift'   => {
            'dynamic'  => 'no',
            'type'     => 'random',
            'backends' => $apps['swift']['backends'][$apps['swift']['route']],
            'be_opts'  => {
                'port'                  => 80,
                'connect_timeout'       => '5s',
                'first_byte_timeout'    => '35s',
                'max_connections'       => 1000,
            }
        },
        'swift_thumbs'   => {
            'dynamic'  => 'no',
            'type'     => 'random',
            'backends' => $apps['swift_thumbs']['backends'][$apps['swift_thumbs']['route']],
            'be_opts'  => {
                'port'                  => 80,
                'connect_timeout'       => '5s',
                'first_byte_timeout'    => '35s',
                'max_connections'       => 1000,
            }
        },
    }

    $common_vcl_config = {
        'cache4xx'         => '1m',
        'purge_host_regex' => $::role::cache::base::purge_host_only_upload_re,
        'upload_domain'    => $::role::cache::base::upload_domain,
        'allowed_methods'  => '^(GET|HEAD|OPTIONS|PURGE)$',
    }

    # Note pass_random true in BE, false in FE below.
    # upload VCL has known FE->BE differentials on pass decisions:
    # 1. FEs pass all range reqs, BEs pass only those which start >32MB
    # 2. FEs pass all objs >32MB in size, BEs do not
    # Because of this, pass_random does more harm than good in the
    # upload-frontend case.  All tiers of backend share the same policies.

    $be_vcl_config = merge($common_vcl_config, {
        'ttl_fixed'        => '7d',
        'pass_random'      => true,
    })

    $fe_vcl_config = merge($common_vcl_config, {
        'ttl_cap'          => '1h',
        'pass_random'      => false,
    })

    $storage_size_bigobj = floor($::role::cache::2layer::storage_size / 6)
    $storage_size_up = $::role::cache::2layer::storage_size - $storage_size_bigobj
    $upload_storage_args = join([
        "-s main1=persistent,/srv/${::role::cache::2layer::storage_parts[0]}/varnish.main1,${storage_size_up}G,${::role::cache::2layer::mma[0]}",
        "-s main2=persistent,/srv/${::role::cache::2layer::storage_parts[1]}/varnish.main2,${storage_size_up}G,${::role::cache::2layer::mma[1]}",
        "-s bigobj1=file,/srv/${::role::cache::2layer::storage_parts[0]}/varnish.bigobj1,${storage_size_bigobj}G",
        "-s bigobj2=file,/srv/${::role::cache::2layer::storage_parts[1]}/varnish.bigobj2,${storage_size_bigobj}G",
    ], ' ')

    role::cache::instances { 'upload':
        fe_mem_gb        => ceiling(0.25 * $::memorysize_mb / 1024.0),
        runtime_params   => ['default_ttl=2592000'],
        app_directors    => $app_directors,
        app_be_opts      => [],
        fe_vcl_config    => $fe_vcl_config,
        be_vcl_config    => $be_vcl_config,
        fe_extra_vcl     => ['upload-common'],
        be_extra_vcl     => ['upload-common'],
        be_storage       => $upload_storage_args,
        fe_cache_be_opts => $fe_cache_be_opts,
        be_cache_be_opts => $be_cache_be_opts,
        cluster_nodes    => hiera('cache::upload::nodes'),
    }

    # Media browser cache hit rate and request volume stats.
    ::varnish::logging::media { 'media':
        statsd_server => 'statsd.eqiad.wmnet',
    }
}
