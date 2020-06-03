class profile::query_service::gui (
    Stdlib::Unixpath $package_dir = hiera('profile::query_service::package_dir'),
    Stdlib::Unixpath $data_dir = hiera('profile::query_service::data_dir'),
    Stdlib::Unixpath $log_dir = hiera('profile::query_service::log_dir'),
    Query_service::DeployMode $deploy_mode = hiera('profile::query_service::deploy_mode'),
    String $deploy_name = hiera('profile::query_service::deploy_name'),
    Boolean $enable_ldf = hiera('profile::query_service::enable_ldf', false),
    Integer $max_query_time_millis = hiera('profile::query_service::max_query_time_millis', 60000),
    Boolean $high_query_time_port = hiera('profile::query_service::high_query_time_port', false),
) {
    require ::profile::query_service::common

    $username = 'blazegraph'

    class { 'query_service::gui':
        deploy_mode           => $deploy_mode,
        package_dir           => $package_dir,
        data_dir              => $data_dir,
        log_dir               => $log_dir,
        deploy_name           => $deploy_name,
        username              => $username,
        enable_ldf            => $enable_ldf,
        max_query_time_millis => $max_query_time_millis,
    }

    if $high_query_time_port {
        # port 8888 accepts queries and runs them with a higher time limit.
        # Let's allow $DOMAIN_NETWORKS access this port for now while
        # we find a way around limiting access to only
        # $ANALYTICS_NETWORKS and LVSes.
        ferm::service { 'query_service_heavy_queries_http':
            proto  => 'tcp',
            port   => '8888',
            srange => '$DOMAIN_NETWORKS';
        }
    }

    class { 'query_service::monitor::gui': }
}
