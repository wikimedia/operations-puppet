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
    $admission_policy = hiera('profile::cache::base::admission_policy', 'nhw'),
) {
    require ::profile::cache::base

    # Temp. experiment to duplicate/mirror the webrequest data
    # to the new Kafka Jumbo brokers.
    include ::profile::cache::kafka::webrequest::duplicate

    $cache_route = $cache_route_table[$::site]
    class { 'tlsproxy::prometheus': }
    class { 'prometheus::node_vhtcpd': }

    class { '::lvs::realserver':
        realserver_ips => $lvs::configuration::service_ips['misc_web'][$::site],
    }

    $fe_cache_be_opts = {
        'port'                  => 3128,
        'connect_timeout'       => '5s',
        'first_byte_timeout'    => '185s',
        'between_bytes_timeout' => '60s',
        'max_connections'       => 50000,
        'probe'                 => 'varnish',
    }

    $be_cache_be_opts = {
        'port'                  => 3128,
        'connect_timeout'       => '5s',
        'first_byte_timeout'    => '185s',
        'between_bytes_timeout' => '60s',
        'max_connections'       => 50000,
        'probe'                 => 'varnish',
    }

    $common_vcl_config = {
        'allowed_methods'  => '^(GET|DELETE|HEAD|PATCH|POST|PURGE|PUT|OPTIONS)$',
        'purge_host_regex' => $::profile::cache::base::purge_host_not_upload_re,
        'pass_random'      => true,
        'req_handling'     => $req_handling,
    }

    $fe_vcl_config = merge($common_vcl_config, {
        'admission_policy' => $admission_policy,
        'fe_mem_gb'        => $::varnish::common::fe_mem_gb,
    })

    class { 'cacheproxy::instance_pair':
        cache_type       => 'misc',
        fe_jemalloc_conf => 'lg_dirty_mult:8,lg_chunk:16',
        app_directors    => $app_directors,
        app_def_be_opts  => $app_def_be_opts,
        fe_vcl_config    => $fe_vcl_config,
        be_vcl_config    => $common_vcl_config,
        fe_extra_vcl     => ['misc-common', 'zero'],
        be_extra_vcl     => ['misc-common'],
        be_storage       => $::profile::cache::base::file_storage_args,
        fe_cache_be_opts => $fe_cache_be_opts,
        be_cache_be_opts => $be_cache_be_opts,
        cluster_nodes    => $nodes,
        cache_route      => $cache_route,
    }
}
