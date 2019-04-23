class profile::cache::varnish::frontend (
    $cache_cluster = hiera('cache::cluster'),
    $common_vcl_config = hiera('profile::cache::varnish::common_vcl_config'),
    $fe_vcl_config = hiera('profile::cache::varnish::frontend::fe_vcl_config'),
    $fe_cache_be_opts = hiera('profile::cache::varnish::cache_be_opts'),
    $fe_jemalloc_conf = hiera('profile::cache::varnish::frontend::fe_jemalloc_conf'),
    $fe_extra_vcl = hiera('profile::cache::varnish::frontend::fe_extra_vcl'),
    $req_handling = hiera('cache::req_handling'),
    $alternate_domains = hiera('cache::alternate_domains', {}),
    $separate_vcl = hiera('profile::cache::varnish::separate_vcl', []),
    $fe_transient_gb = hiera('profile::cache::varnish::frontend::transient_gb', 0),
) {
    require ::profile::cache::base
    $wikimedia_nets = $profile::cache::base::wikimedia_nets
    $wikimedia_trust = $profile::cache::base::wikimedia_trust

    # lint:ignore:wmf_styleguide
    # TODO: consider using a single cache::nodes hash with the cache cluster as
    # key: { 'text': ..., 'upload':, ... }
    $cluster_nodes = hiera("cache::${cache_cluster}::nodes")
    # lint:endignore

    class { '::lvs::realserver':
        realserver_ips => $lvs::configuration::service_ips[$cache_cluster][$::site],
    }

    $vcl_config = $common_vcl_config + $fe_vcl_config + {
        req_handling      => $req_handling,
        alternate_domains => $alternate_domains
    }

    # VCL files common to all instances
    class { 'varnish::common::vcl':
        vcl_config => $vcl_config,
    }

    if $cache_cluster == 'text' {
        # for VCL compilation using libGeoIP
        class { '::geoip': }
        class { '::geoip::dev': }

        # ResourceLoader browser cache hit rate and request volume stats.
        ::varnish::logging::rls { 'rls':
        }
    }

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

    # Transient storage limits T164768
    if $fe_transient_gb > 0 {
        $fe_transient_storage = "-s Transient=malloc,${fe_transient_gb}G"
    }

    # lint:ignore:arrow_alignment
    varnish::instance { "${cache_cluster}-frontend":
        instance_name      => 'frontend',
        layer              => 'frontend',
        vcl                => "${cache_cluster}-frontend",
        separate_vcl       => $separate_vcl.map |$vcl| { "${vcl}-frontend" },
        extra_vcl          => $fe_extra_vcl,
        ports              => [ '80', '3120', '3121', '3122', '3123', '3124', '3125', '3126', '3127' ],
        admin_port         => 6082,
        storage            => "-s malloc,${fe_mem_gb}G ${fe_transient_storage}",
        jemalloc_conf      => $fe_jemalloc_conf,
        backend_caches     => {
          'cache_local' => {
                'dc'       => $::site,
                'service'  => 'varnish-be',
                'backends' => $cluster_nodes[$::site],
                'be_opts'  => $fe_cache_be_opts,
          },
        },
        vcl_config         => $vcl_config,
        wikimedia_nets     => $wikimedia_nets,
        wikimedia_trust    => $wikimedia_trust,
    }
    # lint:endignore
}
