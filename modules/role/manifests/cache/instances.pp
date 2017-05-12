# This defines the pair of varnish::instance for a 2-layer (fe+be) cache node
define role::cache::instances (
    $fe_jemalloc_conf,
    $fe_runtime_params,
    $be_runtime_params,
    $app_directors,
    $app_def_be_opts,
    $fe_vcl_config,
    $be_vcl_config,
    $fe_extra_vcl,
    $be_extra_vcl,
    $fe_cache_be_opts,
    $be_cache_be_opts,
    $be_storage,
    $cluster_nodes
) {

    $cache_route_table = hiera('cache::route_table')
    $cache_route = $cache_route_table[$::site]

    # ideally this could be built with "map"...
    # also, in theory all caches sites should be listed here for flexibility,
    # but as we'll only have other DCs backending to eqiad and/or codfw for
    # now, there's no sense generating the extra churn in terms of reload-vcl
    # on confd changes, etc, for now.  Add more here if we need to use them as
    # cache backend targets for other DCs.  The next-most-likely future
    # scenario for that is backending an asia pop to ulsfo.

    $backend_caches = {
        'cache_eqiad' => {
            'dc'       => 'eqiad',
            'service'  => 'varnish-be',
            'backends' => $cluster_nodes['eqiad'],
            'be_opts'  => $be_cache_be_opts,
        },
        'cache_codfw' => {
            'dc'       => 'codfw',
            'service'  => 'varnish-be',
            'backends' => $cluster_nodes['codfw'],
            'be_opts'  => $be_cache_be_opts,
        },
    }

    # the production conditional is sad (vs using hiera), but I
    # don't know of a better way to factor this out at the moment,
    # and it may all change later...
    if $::realm != 'production' or $::hostname == 'cp1008' {
        $becaches_filtered = hash_deselect_re('^cache_codfw', $backend_caches)
    } else {
        $becaches_filtered = $backend_caches
    }

    $our_backend_caches = hash_deselect_re("^cache_${::site}", $becaches_filtered)

    # Frontend memory cache sizing
    $mem_gb = $::memorysize_mb / 1024.0
    if ($mem_gb < 90.0) {
        # virtuals, test hosts, etc...
        $fe_mem_gb = 1
    } else {
        # Removing a constant factor before scaling helps with
        # low-memory hosts, as they need more relative space to
        # handle all the non-cache basics.
        $fe_mem_gb = ceiling(0.7 * ($mem_gb - 80.0))
    }

    # Experimental backend settings to handle T145661
    if hiera('cache::exp_thread_rt', false) {
        $exp_thread_params = ['exp_thread_rt=true','exp_lck_inherit=true']
    } else {
        $exp_thread_params = []
    }

    # backends: Should increase nuke success chances, and reduce LRU lock/modify rate
    $nuke_lru_params = ['nuke_limit=1000','lru_interval=31']

    varnish::instance { "${title}-backend":
        name               => '',
        layer              => 'backend',
        vcl                => "${title}-backend",
        extra_vcl          => $be_extra_vcl,
        ports              => [ 3128 ],
        admin_port         => 6083,
        runtime_parameters => concat($be_runtime_params, $nuke_lru_params, $exp_thread_params),
        storage            => $be_storage,
        vcl_config         => $be_vcl_config,
        app_directors      => $app_directors,
        app_def_be_opts    => $app_def_be_opts,
        backend_caches     => $our_backend_caches,
    }

    # Set a reduced keep value for frontends
    $fe_keep_vcl_config = merge($fe_vcl_config, { 'keep' => '1d', })

    # lint:ignore:arrow_alignment
    varnish::instance { "${title}-frontend":
        name               => 'frontend',
        layer              => 'frontend',
        vcl                => "${title}-frontend",
        extra_vcl          => $fe_extra_vcl,
        ports              => [ 80, 3120, 3121, 3122, 3123, 3124, 3125, 3126, 3127 ],
        admin_port         => 6082,
        runtime_parameters => $fe_runtime_params,
        storage            => "-s malloc,${fe_mem_gb}G",
        jemalloc_conf      => $fe_jemalloc_conf,
        backend_caches     => {
            'cache_local' => {
                'dc'       => $::site,
                'service'  => 'varnish-be',
                'backends' => $cluster_nodes[$::site],
                'be_opts'  => $fe_cache_be_opts,
            },
        },
        vcl_config         => $fe_keep_vcl_config,
    }
    # lint:endignore
}
