# == Class profile::cache::misc
#
# Configures a misc-cluster varnish node with 2 instances and TLS termination
#
class profile::cache::misc(
    $nodes = hiera('cache::misc::nodes'),
    $req_handling = hiera('cache::req_handling'),
    $app_directors = hiera('cache::app_directors'),
    $app_def_be_opts = hiera('cache::app_def_be_opts'),
    $cache_route_table = hiera('cache::route_table'),
    $varnish_version = hiera('profile::cache::base::varnish_version', 4),
) {
    require ::profile::cache::base

    $cache_route = $cache_route_table[$::site]
    class { 'tlsproxy::prometheus': }
    class { 'prometheus::node_vhtcpd': }

    class { 'varnish::htcppurger':
        mc_addrs => [ '239.128.0.115' ],
    }

    class { '::lvs::realserver':
        realserver_ips => $lvs::configuration::service_ips['misc_web'][$::site],
    }

    $fe_cache_be_opts = {
        'port'                  => 3128,
        'connect_timeout'       => '5s',
        'first_byte_timeout'    => '185s',
        'max_connections'       => 100000,
        'probe'                 => 'varnish',
    }

    $be_cache_be_opts = {
        'port'                  => 3128,
        'connect_timeout'       => '5s',
        'first_byte_timeout'    => '185s',
        'max_connections'       => 100,
        'probe'                 => 'varnish',
    }

    $common_vcl_config = {
        'allowed_methods'  => '^(GET|DELETE|HEAD|PATCH|POST|PURGE|PUT|OPTIONS)$',
        'purge_host_regex' => $::profile::cache::base::purge_host_not_upload_re,
        'pass_random'      => true,
        'req_handling'     => $req_handling,
    }

    $common_runtime_params = ['default_ttl=3600']

    # The default timeout_idle setting, 5s, seems to be causing sc_rx_timeout
    # issues in our setup. See T159429
    $be_runtime_params = ['timeout_idle=120']

    class { 'cacheproxy::instance_pair':
        cache_type        => 'misc',
        fe_jemalloc_conf  => 'lg_dirty_mult:8,lg_chunk:16',
        fe_runtime_params => $common_runtime_params,
        be_runtime_params => concat($common_runtime_params, $be_runtime_params),
        app_directors     => $app_directors,
        app_def_be_opts   => $app_def_be_opts,
        fe_vcl_config     => $common_vcl_config,
        be_vcl_config     => $common_vcl_config,
        fe_extra_vcl      => ['misc-common', 'zero'],
        be_extra_vcl      => ['misc-common'],
        be_storage        => $::profile::cache::base::file_storage_args,
        fe_cache_be_opts  => $fe_cache_be_opts,
        be_cache_be_opts  => $be_cache_be_opts,
        cluster_nodes     => $nodes,
        cache_route       => $cache_route,
        varnish_version   => $varnish_version,
    }
}
