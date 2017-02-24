# filtertags: labs-project-deployment-prep
class role::cache::upload(
    $upload_domain = 'upload.wikimedia.org',
) {
    include role::cache::base
    include role::cache::ssl::unified
    include ::standard

    class { 'prometheus::node_vhtcpd': }

    class { 'varnish::htcppurger':
        host_regex => 'upload',
        mc_addrs   => [ '239.128.0.112', '239.128.0.113' ],
    }

    class { '::lvs::realserver':
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
        'max_connections'       => 10000,
        'probe'                 => 'varnish',
    }

    $app_def_be_opts = {
        'port'                  => 80,
        'connect_timeout'       => '5s',
        'first_byte_timeout'    => '35s',
        'max_connections'       => 10000,
    }

    $app_directors = {
        'swift'   => {
            'backend' => 'ms-fe.svc.eqiad.wmnet',
        },
        'swift_thumbs'   => {
            'backend' => 'ms-fe-thumbs.svc.eqiad.wmnet',
        },
    }

    $req_handling = {
        'default' => {
            'director' => 'swift',
            'subpaths' => {
                '^/+[^/]+/[^/]+/thumb/' => {
                    director => 'swift_thumbs',
                },
            },
        },
    }

    $common_vcl_config = {
        'purge_host_regex' => $::role::cache::base::purge_host_only_upload_re,
        'upload_domain'    => $upload_domain,
        'allowed_methods'  => '^(GET|HEAD|OPTIONS|PURGE)$',
        'req_handling'     => $req_handling,
    }

    # Note pass_random true in BE, false in FE below.
    # upload VCL has known FE->BE differentials on pass decisions:
    # 1. FEs pass all range reqs, BEs pass only those which start >32MB
    # 2. FEs pass all objs >32MB in size, BEs do not
    # Because of this, pass_random does more harm than good in the
    # upload-frontend case.  All tiers of backend share the same policies.

    $be_vcl_config = merge($common_vcl_config, {
        'pass_random'               => true,
    })

    $fe_vcl_config = merge($common_vcl_config, {
        'ttl_cap'          => '1d',
        'pass_random'      => false,
    })

    # See T145661 for storage binning rationale
    $sda = $::role::cache::base::storage_parts[0]
    $sdb = $::role::cache::base::storage_parts[1]
    $ssm = $::role::cache::base::storage_size * 2 * 1024
    $bin0_size = floor($ssm * 0.03)
    $bin1_size = floor($ssm * 0.20)
    $bin2_size = floor($ssm * 0.43)
    $bin3_size = floor($ssm * 0.30)
    $bin4_size = floor($ssm * 0.04)
    $upload_storage_args = join([
        "-s bin0=file,/srv/${sda}/varnish.bin0,${bin0_size}M",
        "-s bin1=file,/srv/${sdb}/varnish.bin1,${bin1_size}M",
        "-s bin2=file,/srv/${sda}/varnish.bin2,${bin2_size}M",
        "-s bin3=file,/srv/${sdb}/varnish.bin3,${bin3_size}M",
        "-s bin4=file,/srv/${sda}/varnish.bin4,${bin4_size}M",
    ], ' ')

    # default_ttl=7d
    $common_runtime_params = ['default_ttl=604800']

    # Bumping nuke_limit and lru_interval helps with T145661
    $be_runtime_params = ['nuke_limit=1000','lru_interval=31']

    role::cache::instances { 'upload':
        fe_mem_gb         => ceiling(0.4 * $::memorysize_mb / 1024.0),
        fe_jemalloc_conf  => 'lg_dirty_mult:8,lg_chunk:17',
        fe_runtime_params => $common_runtime_params,
        be_runtime_params => concat($common_runtime_params, $be_runtime_params),
        app_directors     => $app_directors,
        app_def_be_opts   => $app_def_be_opts,
        fe_vcl_config     => $fe_vcl_config,
        be_vcl_config     => $be_vcl_config,
        fe_extra_vcl      => ['upload-common'],
        be_extra_vcl      => ['upload-common'],
        be_storage        => $upload_storage_args,
        fe_cache_be_opts  => $fe_cache_be_opts,
        be_cache_be_opts  => $be_cache_be_opts,
        cluster_nodes     => hiera('cache::upload::nodes'),
    }

    # Media browser cache hit rate and request volume stats.
    ::varnish::logging::media { 'media':
        statsd_server => hiera('statsd'),
    }
}
