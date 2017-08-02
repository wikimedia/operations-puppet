class profile::wdqs (
    $log_aggregator = hiera('profile::wdqs::log_aggregator'),
    $use_git_deploy = hiera('profile::wdqs::use_git_deploy'),
    $package_dir = hiera('profile::wdqs::package_dir'),
    $data_dir = hiera('profile::wdqs::data_dir'),
    $endpoint = hiera('profile::wdqs::endpoint'),
    $blazegraph_options = hiera('profile::wdqs::blazegraph_options'),
    $blazegraph_heap_size = hiera('profile::wdqs::blazegraph_heap_size'),
    $blazegraph_config_file = hiera('profile::wdqs::blazegraph_config_file'),
    $updater_options = hiera('profile::wdqs::updater_options'),
) {
    $nagios_contact_group = 'admins,wdqs-admins'

    # Install services - both blazegraph and the updater
    class { '::wdqs':
        use_git_deploy         => $use_git_deploy,
        package_dir            => $package_dir,
        data_dir               => $data_dir,
        endpoint               => $endpoint,
        blazegraph_options     => $blazegraph_options,
        blazegraph_heap_size   => $blazegraph_heap_size,
        blazegraph_config_file => $blazegraph_config_file,
    }

    # WDQS Updater service
    class { 'wdqs::updater':
        options => $updater_options,
    }

    # Service Web proxy
    class { '::wdqs::gui':
        log_aggregator => $log_aggregator,
    }

    # Firewall
    ferm::service {
        'wdqs_http':
            proto => 'tcp',
            port  => '80';
        'wdqs_https':
            proto => 'tcp',
            port  => '443';
        'wdqs_internal_http':
            proto  => 'tcp',
            port   => '8888',
            srange => '$DOMAIN_NETWORKS';
    }

    # Monitoring
    class { '::wdqs::monitor::blazegraph': }
    class { '::wdqs::monitor::updater': }
    class { '::wdqs::monitor::services': }
}