# filtertags: labs-project-deployment-prep
class role::cache::upload(
    $upload_domain = 'upload.wikimedia.org',
    $maps_domain = 'maps.wikimedia.org',
) {
    system::role { 'cache::upload':
        description => 'upload Varnish cache server',
    }

    include profile::cache::base
    include role::cache::ssl::unified
    include ::standard

    class { 'tlsproxy::prometheus': }
    class { 'prometheus::node_vhtcpd': }

    class { 'varnish::htcppurger':
        host_regex => '[um][pa][lp][os]', # like 'uplo|maps', but avoiding shell metachar...
        mc_addrs   => [ '239.128.0.112', '239.128.0.113', '239.128.0.114' ],
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

    $common_vcl_config = {
        'purge_host_regex' => $::profile::cache::base::purge_host_only_upload_re,
        'upload_domain'    => $upload_domain,
        'maps_domain'      => $maps_domain,
        'allowed_methods'  => '^(GET|HEAD|OPTIONS|PURGE)$',
        'req_handling'     => hiera('cache::req_handling'),
    }

    # Note pass_random true in BE, false in FE below.
    # upload VCL has known FE->BE differentials on pass decisions:
    # 1. FEs pass all range reqs, BEs pass only those which start >32MB
    # 2. FEs pass all objs >32MB in size, BEs do not
    # Because of this, pass_random does more harm than good in the
    # upload-frontend case.  All tiers of backend share the same policies.

    $be_vcl_config = merge($common_vcl_config, {
        'pass_random' => true,
    })

    $fe_vcl_config = merge($common_vcl_config, {
        'pass_random' => false,
    })

    # See T145661 for storage binning rationale
    $sda = $::profile::cache::base::storage_parts[0]
    $sdb = $::profile::cache::base::storage_parts[1]
    $ssm = $::profile::cache::base::storage_size * 2 * 1024
    $bin0_size = floor($ssm * 0.04)
    $bin1_size = floor($ssm * 0.23)
    $bin2_size = floor($ssm * 0.40)
    $bin3_size = floor($ssm * 0.27)
    $bin4_size = floor($ssm * 0.06)
    $upload_storage_args = join([
        "-s bin0=file,/srv/${sda}/varnish.bin0,${bin0_size}M",
        "-s bin1=file,/srv/${sdb}/varnish.bin1,${bin1_size}M",
        "-s bin2=file,/srv/${sda}/varnish.bin2,${bin2_size}M",
        "-s bin3=file,/srv/${sdb}/varnish.bin3,${bin3_size}M",
        "-s bin4=file,/srv/${sda}/varnish.bin4,${bin4_size}M",
    ], ' ')

    $common_runtime_params = ['default_ttl=86400']

    class { 'role::cache::instances':
        cache_type        => 'upload',
        fe_jemalloc_conf  => 'lg_dirty_mult:8,lg_chunk:17',
        fe_runtime_params => $common_runtime_params,
        be_runtime_params => $common_runtime_params,
        app_directors     => hiera('cache::app_directors'),
        app_def_be_opts   => hiera('cache::app_def_be_opts'),
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
