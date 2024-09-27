# SPDX-License-Identifier: Apache-2.0
class profile::query_service::gui (
    String $username = lookup('profile::query_service::username'),
    Stdlib::Unixpath $package_dir = lookup('profile::query_service::package_dir'),
    Stdlib::Unixpath $data_dir = lookup('profile::query_service::data_dir'),
    Stdlib::Unixpath $log_dir = lookup('profile::query_service::log_dir'),
    String $deploy_name = lookup('profile::query_service::deploy_name'),
    Boolean $enable_ldf = lookup('profile::query_service::enable_ldf', {default_value => false}),
    Integer $max_query_time_millis = lookup('profile::query_service::max_query_time_millis', {default_value => 60000}),
    Boolean $high_query_time_port = lookup('profile::query_service::high_query_time_port', {default_value => false}),
    String $blazegraph_main_ns = lookup('profile::query_service::blazegraph_main_ns'),
    Boolean $oauth = lookup('profile::query_service::oauth'),
    Optional[Stdlib::HTTPSUrl] $gui_url = lookup('profile::query_service::gui_url', {default_value => undef}),
    Array[String] $monitoring_user_agents = lookup('profile::query_service::monitoring_user_agents', {default_value => []}),
    Boolean $only_throttle_cdn = lookup('profile::query_service::only_throttle_cdn', {'default_value' => false}),
) {
    require ::profile::query_service::common

    class { 'query_service::gui':
        package_dir            => $package_dir,
        data_dir               => $data_dir,
        log_dir                => $log_dir,
        deploy_name            => $deploy_name,
        username               => $username,
        enable_ldf             => $enable_ldf,
        max_query_time_millis  => $max_query_time_millis,
        blazegraph_main_ns     => $blazegraph_main_ns,
        oauth                  => $oauth,
        gui_url                => $gui_url,
        monitoring_user_agents => $monitoring_user_agents,
        only_throttle_cdn      => $only_throttle_cdn,
    }

    if $high_query_time_port {
        # port 8888 accepts queries and runs them with a higher time limit.
        # Let's allow $DOMAIN_NETWORKS access this port for now while
        # we find a way around limiting access to only
        # $ANALYTICS_NETWORKS and LVSes.
        firewall::service { 'query_service_heavy_queries_http':
            proto    => 'tcp',
            port     => 8888,
            src_sets => ['DOMAIN_NETWORKS'],
        }
    }

}
