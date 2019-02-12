# This defines the pair of varnish::instance for a 2-layer (fe+be) cache node
class cacheproxy::instance_pair (
    $cache_type,
    $fe_jemalloc_conf,
    $app_directors,
    $app_def_be_opts,
    $fe_vcl_config,
    $be_vcl_config,
    $fe_extra_vcl,
    $be_extra_vcl,
    $fe_cache_be_opts,
    $be_cache_be_opts,
    $be_storage,
    $cluster_nodes,
    $cache_route,
    $fe_transient_gb=0,
    $be_transient_gb=0,
    $backend_warming=false,
    $separate_vcl=[],
    $wikimedia_nets=[],
    $wikimedia_trust=[],
) {
    # ideally this could be built with "map"...
    # also, in theory all caches sites should be listed here for flexibility,
    # but as we'll only have other DCs backending to eqiad and/or codfw for
    # now, there's no sense generating the extra churn in terms of reload-vcl
    # on confd changes, etc, for now.  Add more here if we need to use them as
    # cache backend targets for other DCs.

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

    # Transient storage limits T164768

    if $fe_transient_gb > 0 {
        $fe_transient_storage = "-s Transient=malloc,${fe_transient_gb}G"
    }

    if $be_transient_gb > 0 {
        $be_transient_storage = "-s Transient=malloc,${be_transient_gb}G"
    }

    # VCL files common to all instances. It's actually ok to declare it here as this module depends
    # on the varnish one
    # lint:ignore:wmf_styleguide
    class { 'varnish::common::vcl':
        vcl_config => $fe_vcl_config,
    }
    # lint:endignore

    # Set backend_warming to enable/disable miss2pass behavior
    $be_warming_vcl_config = merge($be_vcl_config, {
        'backend_warming' => $backend_warming,
    })

    varnish::instance { "${cache_type}-backend":
        instance_name   => '',
        layer           => 'backend',
        vcl             => "${cache_type}-backend",
        separate_vcl    => $separate_vcl.map |$vcl| { "${vcl}-backend" },
        extra_vcl       => $be_extra_vcl,
        ports           => [ '3128' ],
        admin_port      => 6083,
        storage         => "${be_storage} ${be_transient_storage}",
        vcl_config      => $be_warming_vcl_config,
        app_directors   => $app_directors,
        app_def_be_opts => $app_def_be_opts,
        backend_caches  => $our_backend_caches,
        wikimedia_nets  => $wikimedia_nets,
        wikimedia_trust => $wikimedia_trust,
    }

    # Set a reduced keep value for frontends
    $fe_keep_vcl_config = merge($fe_vcl_config, { 'keep' => '1d', })

    # lint:ignore:arrow_alignment
    varnish::instance { "${cache_type}-frontend":
        instance_name      => 'frontend',
        layer              => 'frontend',
        vcl                => "${cache_type}-frontend",
        separate_vcl       => $separate_vcl.map |$vcl| { "${vcl}-frontend" },
        extra_vcl          => $fe_extra_vcl,
        ports              => [ '80', '3120', '3121', '3122', '3123', '3124', '3125', '3126', '3127' ],
        admin_port         => 6082,
        storage            => "-s malloc,${::varnish::common::fe_mem_gb}G ${fe_transient_storage}",
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
        wikimedia_nets     => $wikimedia_nets,
        wikimedia_trust    => $wikimedia_trust,
    }
    # lint:endignore
}
