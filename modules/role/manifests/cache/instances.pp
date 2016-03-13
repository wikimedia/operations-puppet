# This defines the pair of varnish::instance for a 2layer/2tier cache cluster
define role::cache::instances (
    $fe_mem_gb,
    $runtime_params,
    $app_directors,
    $app_be_opts,
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
            'dynamic'  => 'yes',
            'type'     => 'chash',
            'dc'       => 'eqiad',
            'service'  => 'varnish-be',
            'backends' => $cluster_nodes['eqiad'],
            'be_opts'  => $be_cache_be_opts,
        },
        'cache_eqiad_random' => {
            'dynamic'  => 'yes',
            'type'     => 'random',
            'dc'       => 'eqiad',
            'service'  => 'varnish-be-rand',
            'backends' => $cluster_nodes['eqiad'],
            'be_opts'  => $be_cache_be_opts,
        }
    }

    if $::realm == 'production' {
        $backend_caches['cache_codfw'] = {
            'dynamic'  => 'yes',
            'type'     => 'chash',
            'dc'       => 'codfw',
            'service'  => 'varnish-be',
            'backends' => $cluster_nodes['codfw'],
            'be_opts'  => $be_cache_be_opts,
        }
        $backend_caches['cache_codfw_random'] = {
            'dynamic'  => 'yes',
            'type'     => 'random',
            'dc'       => 'codfw',
            'service'  => 'varnish-be-rand',
            'backends' => $cluster_nodes['codfw'],
            'be_opts'  => $be_cache_be_opts,
        }
    }

    # temporary hack for cache_maps, because it's not fully deployed T109162
    if $title == 'maps' {
        $becaches_filtered = hash_deselect_re('^cache_codfw', $backend_caches)
    } else {
        $becaches_filtered = $backend_caches
    }

    $our_backend_caches = hash_deselect_re("^cache_${::site}", $becaches_filtered)
    $be_directors = merge($app_directors, $our_backend_caches)

    varnish::instance { "${title}-backend":
        name               => '',
        layer              => 'backend',
        vcl                => "${title}-backend",
        extra_vcl          => $be_extra_vcl,
        ports              => [ 3128 ],
        admin_port         => 6083,
        runtime_parameters => $runtime_params,
        storage            => $be_storage,
        vcl_config         => $be_vcl_config,
        directors          => $be_directors,
    }

    varnish::instance { "${title}-frontend":
        name               => 'frontend',
        layer              => 'frontend',
        vcl                => "${title}-frontend",
        extra_vcl          => $fe_extra_vcl,
        ports              => [ 80 ],
        admin_port         => 6082,
        runtime_parameters => $runtime_params,
        storage            => "-s malloc,${fe_mem_gb}G",
        directors          => {
            'cache_local' => {
                'dynamic'  => 'yes',
                'type'     => 'chash',
                'dc'       => $::site,
                'service'  => 'varnish-be',
                'backends' => $cluster_nodes[$::site],
                'be_opts'  => $fe_cache_be_opts,
            },
            'cache_local_random' => {
                'dynamic'  => 'yes',
                'type'     => 'random',
                'dc'       => $::site,
                'service'  => 'varnish-be-rand',
                'backends' => $cluster_nodes[$::site],
                'be_opts'  => $fe_cache_be_opts,
            },
        },
        vcl_config         => $fe_vcl_config,
    }
}
