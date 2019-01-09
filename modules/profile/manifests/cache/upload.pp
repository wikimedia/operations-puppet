class profile::cache::upload(
    $upload_domain = hiera('profile::cache::upload::upload_domain', 'upload.wikimedia.org'),
    $upload_webp_hits_threshold = hiera('profile::cache::upload::upload_webp_hits_threshold', 10000),
    $maps_domain = hiera('profile::cache::upload::maps_domain', 'maps.wikimedia.org'),
    $req_handling = hiera('cache::req_handling'),
    $app_directors = hiera('cache::app_directors'),
    $app_def_be_opts = hiera('cache::app_def_be_opts'),
    $cluster_nodes = hiera('cache::upload::nodes'),
    $statsd_server = hiera('statsd'),
    $cache_route_table = hiera('cache::route_table'),
    $backend_warming = hiera('cache::backend_warming', false),
    $admission_policy = hiera('profile::cache::base::admission_policy', 'nhw'),
    $ats_backends = hiera('cache::ats_backends', false),
) {
    require ::profile::cache::base

    $cache_route = $cache_route_table[$::site]
    class { 'tlsproxy::prometheus': }
    class { 'prometheus::node_vhtcpd': }

    class { '::lvs::realserver':
        realserver_ips => $lvs::configuration::service_ips['upload'][$::site],
    }

    $fe_cache_be_opts = {
        'port'                  => 3128,
        'connect_timeout'       => '5s',
        'first_byte_timeout'    => '35s',
        'between_bytes_timeout' => '60s',
        'max_connections'       => 50000,
        'probe'                 => 'varnish',
    }

    $be_cache_be_opts = {
        'port'                  => 3128,
        'connect_timeout'       => '5s',
        'first_byte_timeout'    => '35s',
        'between_bytes_timeout' => '60s',
        'max_connections'       => 50000,
        'probe'                 => 'varnish',
    }

    $common_vcl_config = {
        'purge_host_regex'           => $::profile::cache::base::purge_host_only_upload_re,
        'upload_domain'              => $upload_domain,
        'upload_webp_hits_threshold' => $upload_webp_hits_threshold,
        'maps_domain'                => $maps_domain,
        'allowed_methods'            => '^(GET|HEAD|OPTIONS|PURGE)$',
        'req_handling'               => $req_handling,
    }

    # Note pass_random true in BE, false in FE below.
    # upload VCL has known FE->BE differentials on pass decisions:
    # 1. FEs pass all range reqs, BEs pass only those which start >32MB
    # 2. FEs pass all objs >32MB in size, BEs do not
    # Because of this, pass_random does more harm than good in the
    # upload-frontend case.  All tiers of backend share the same policies.

    $be_vcl_config = merge($common_vcl_config, {
        'pass_random'      => true,
        'varnish_probe_ms' => $::profile::cache::base::core_probe_timeout_ms,
    })

    $fe_vcl_config = merge($common_vcl_config, {
        'pass_random'      => false,
        'admission_policy' => $admission_policy,
        'fe_mem_gb'        => $::varnish::common::fe_mem_gb,
        # RTT is ~0, but 100ms is to accomodate small local hiccups, similar to
        # the +100 added in $::profile::cache::base::core_probe_timeout_ms
        'varnish_probe_ms' => 100,
    })

    # See T145661 for storage binning rationale
    $sda = $::profile::cache::base::storage_parts[0]
    $sdb = $::profile::cache::base::storage_parts[1]
    if $sda == $sdb {
        $ssm = $::profile::cache::base::storage_size * 1024
    } else {
        $ssm = $::profile::cache::base::storage_size * 2 * 1024
    }
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

    class { 'cacheproxy::instance_pair':
        cache_type       => 'upload',
        fe_jemalloc_conf => 'lg_dirty_mult:8,lg_chunk:17',
        app_directors    => $app_directors,
        app_def_be_opts  => $app_def_be_opts,
        fe_vcl_config    => $fe_vcl_config,
        be_vcl_config    => $be_vcl_config,
        fe_extra_vcl     => ['upload-common', 'normalize_path'],
        be_extra_vcl     => ['upload-common', 'normalize_path'],
        be_storage       => $upload_storage_args,
        fe_cache_be_opts => $fe_cache_be_opts,
        be_cache_be_opts => $be_cache_be_opts,
        cluster_nodes    => $cluster_nodes,
        cache_route      => $cache_route,
        backend_warming  => $backend_warming,
        wikimedia_nets   => $profile::cache::base::wikimedia_nets,
        wikimedia_trust  => $profile::cache::base::wikimedia_trust,
        ats_backends     => $ats_backends,
    }

    # Media browser cache hit rate and request volume stats.
    ::varnish::logging::media { 'media':
    }
}
