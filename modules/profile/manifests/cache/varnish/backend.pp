# == Class: profile::cache::varnish::backend
#
# Sets up a varnish cache backend. This includes:
#
# - storage configuration
# - prometheus exporter for varnish backend on tcp/9131
# - all logging-related services specific to varnish backends
#
# === Parameters
# [*storage_parts*]
#   Array of device names to be used by varnish-be.
#   For example: ['sda3', 'sdb3']
#
# [*statsd_host*]
#   Statsd server hostname
#
# [*nodes*]
#   List of prometheus nodes
#
class profile::cache::varnish::backend (
    $statsd_host = hiera('statsd'),
    $prometheus_nodes = hiera('prometheus_nodes'),
    $cache_cluster = hiera('cache::cluster'),
    $cache_route_table = hiera('cache::route_table'),
    $app_directors = hiera('cache::app_directors'),
    $app_def_be_opts = hiera('cache::app_def_be_opts'),
    $storage_parts = hiera('profile::cache::varnish::backend::storage_parts'),
    $common_vcl_config = hiera('profile::cache::varnish::common_vcl_config'),
    $be_vcl_config = hiera('profile::cache::varnish::backend::be_vcl_config'),
    $be_cache_be_opts = hiera('profile::cache::varnish::cache_be_opts'),
    $be_extra_vcl = hiera('profile::cache::varnish::backend::be_extra_vcl'),
    $max_core_rtt = hiera('max_core_rtt'),
    $req_handling = hiera('cache::req_handling'),
    $alternate_domains = hiera('cache::alternate_domains', {}),
    $separate_vcl = hiera('profile::cache::varnish::separate_vcl', []),
    $backend_warming = hiera('cache::backend_warming', false),
) {
    require ::profile::cache::base
    $wikimedia_nets = $profile::cache::base::wikimedia_nets
    $wikimedia_trust = $profile::cache::base::wikimedia_trust

    # lint:ignore:wmf_styleguide
    # TODO: as in profile::cache::varnish::frontend, consider using a single
    # cache::nodes hash with the cache cluster as key:
    # { 'text': ..., 'upload':, ... }
    $cluster_nodes = hiera("cache::${cache_cluster}::nodes")
    # lint:endignore

    # Varnish probes normally take 2xRTT, so for WAN cases give them
    # an outer max of 3xRTT, + 100ms for local hiccups
    $core_probe_timeout_ms = ($max_core_rtt * 3) + 100

    $vcl_config = $common_vcl_config + $be_vcl_config + {
        backend_warming   => $backend_warming,
        varnish_probe_ms  => $core_probe_timeout_ms,
        req_handling      => $req_handling,
        alternate_domains => $alternate_domains,
    }

    ###########################################################################
    # Find out which backend caches to use
    ###########################################################################

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

    ###########################################################################
    # Storage configuration
    ###########################################################################

    # Varnish backend storage/weight config

    $storage_size = $::hostname ? {
        /^cp1008$/                 => 117,  # Intel X-25M 160G (test host!)
        /^cp30(0[789]|10)$/        => 460,  # Intel M320 600G via H710 (esams misc)
        /^cp[45]0[0-9]{2}$/        => 730,  # Intel S3710 800G (ulsfo + eqsin)
        /^cp10(7[5-9]|8[0-9]|90)$/ => 1490, # Samsung PM1725a 1.6T (new eqiad nodes)
        /^cp[0-9]{4}$/             => 360,  # Intel S3700 400G (codfw, esams text/upload, legacy eqiad)
        default                    => 6,    # 6 is the bare min, for e.g. virtuals
    }

    $filesystems = unique($storage_parts)
    varnish::setup_filesystem { $filesystems: }
    Varnish::Setup_filesystem <| |> -> Varnish::Instance <| |>

    if $cache_cluster == 'upload' {
        # See T145661 for storage binning rationale
        $sda = $storage_parts[0]
        $sdb = $storage_parts[1]
        if $sda == $sdb {
            $ssm = $storage_size * 1024
        } else {
            $ssm = $storage_size * 2 * 1024
        }
        $bin0_size = floor($ssm * 0.04)
        $bin1_size = floor($ssm * 0.23)
        $bin2_size = floor($ssm * 0.40)
        $bin3_size = floor($ssm * 0.27)
        $bin4_size = floor($ssm * 0.06)
        $file_storage_args = join([
            "-s bin0=file,/srv/${sda}/varnish.bin0,${bin0_size}M",
            "-s bin1=file,/srv/${sdb}/varnish.bin1,${bin1_size}M",
            "-s bin2=file,/srv/${sda}/varnish.bin2,${bin2_size}M",
            "-s bin3=file,/srv/${sdb}/varnish.bin3,${bin3_size}M",
            "-s bin4=file,/srv/${sda}/varnish.bin4,${bin4_size}M",
        ], ' ')
    } else {
        $file_storage_args = join($filesystems.map |$idx, $store| { "-s main${$idx + 1}=file,/srv/${store}/varnish.main${$idx + 1},${storage_size}G" }, ' ')
    }

    varnish::instance { "${cache_cluster}-backend":
        instance_name   => '',
        layer           => 'backend',
        vcl             => "${cache_cluster}-backend",
        separate_vcl    => $separate_vcl.map |$vcl| { "${vcl}-backend" },
        extra_vcl       => $be_extra_vcl,
        ports           => [ '3128' ],
        admin_port      => 6083,
        storage         => $file_storage_args,
        vcl_config      => $vcl_config,
        app_directors   => $app_directors,
        app_def_be_opts => $app_def_be_opts,
        cache_route     => $cache_route_table[$::site],
        backend_caches  => $our_backend_caches,
        wikimedia_nets  => $wikimedia_nets,
        wikimedia_trust => $wikimedia_trust,
    }

    # TODO: the production conditional is sad
    if $::realm == 'production' {
        # Periodic varnish backend cron restarts, we need this to mitigate
        # T145661
        class { 'cacheproxy::cron_restart':
            nodes         => $cluster_nodes,
            cache_cluster => $cache_cluster,
        }
    }

    class { 'varnish::logging::backend':
        statsd_host => $statsd_host,
    }

    $prometheus_ferm_nodes = join($prometheus_nodes, ' ')
    $ferm_srange = "(@resolve((${prometheus_ferm_nodes})) @resolve((${prometheus_ferm_nodes}), AAAA))"

    prometheus::varnish_exporter{ 'default': }

    ferm::service { 'prometheus-varnish-exporter':
        proto  => 'tcp',
        port   => '9131',
        srange => $ferm_srange,
    }
}
