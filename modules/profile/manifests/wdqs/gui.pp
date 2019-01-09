class profile::wdqs::gui (
    Stdlib::Unixpath $package_dir = hiera('profile::wdqs::package_dir', '/srv/deployment/wdqs/wdqs'),
    Stdlib::Unixpath $data_dir = hiera('profile::wdqs::data_dir', '/srv/wdqs'),
    Stdlib::Unixpath $log_dir = hiera('profile::wdqs::log_dir', '/var/log/wdqs'),
    Wdqs::DeployMode $deploy_mode = hiera('profile::wdqs::deploy_mode'),
    Boolean $enable_ldf = hiera('profile::wdqs::enable_ldf', false),
    Integer $max_query_time_millis = hiera('profile::wdqs::max_query_time_millis', 60000),
    Boolean $high_query_time_port = hiera('profile::wdqs::high_query_time_port', false),
) {
    require ::profile::wdqs::common

    $username = 'blazegraph'

    class { 'wdqs::gui':
        deploy_mode           => $deploy_mode,
        package_dir           => $package_dir,
        data_dir              => $data_dir,
        log_dir               => $log_dir,
        username              => $username,
        enable_ldf            => $enable_ldf,
        max_query_time_millis => $max_query_time_millis,
    }

    if $high_query_time_port {
        # port 8888 accepts queries and runs them with a higher time limit.
        ferm::service { 'wdqs_internal_http':
            proto  => 'tcp',
            port   => '8888',
            srange => '$DOMAIN_NETWORKS';
        }
    }

    class { 'wdqs::monitor::gui': }
}
