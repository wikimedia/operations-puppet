# = Class: wdqs
# Note: This installs and run blazegraph and updater services.
# data dump data must be loaded manually before running these services
#
# Parameter documentation can be found in wdqs::blazegraph, wdqs::updater, wdqs::gui and wdqs::common
class wdqs(
    String $logstash_host,
    Array[String] $updater_options,
    String $endpoint = '',
    Wmflib::IpPort $logstash_json_port = 11514,
    String $blazegraph_heap_size = '31g',
    String $config_file = 'RWStore.properties',
    Array[String] $blazegraph_options = [],
    Array[String] $blazegraph_extra_jvm_opts = [],
    Array[String] $updater_extra_jvm_opts = [],
    Wdqs::DeployMode $deploy_mode = 'scap3',
    String $username = 'blazegraph',
    Stdlib::Unixpath $package_dir = '/srv/deployment/wdqs/wdqs',
    Stdlib::Unixpath $data_dir = '/srv/wdqs',
    Stdlib::Unixpath $log_dir = '/var/log/wdqs',
    Boolean $enable_ldf = true,
    Integer $max_query_time_millis = 60000,
    Enum['none', 'daily', 'weekly'] $load_categories = 'none',
    Boolean $run_tests = false,
    Boolean $log_sparql = false,
) {
    $deploy_user = 'deploy-service'

    class { 'wdqs::common':
        deploy_mode => $deploy_mode,
        username    => $username,
        deploy_user => $deploy_user,
        package_dir => $package_dir,
        data_dir    => $data_dir,
        log_dir     => $log_dir,
        endpoint    => $endpoint,
    }

    class { 'wdqs::blazegraph':
        package_dir          => $package_dir,
        data_dir             => $data_dir,
        logstash_host        => $logstash_host,
        endpoint             => $endpoint,
        blazegraph_heap_size => $blazegraph_heap_size,
        blazegraph_options   => $blazegraph_options,
        logstash_json_port   => $logstash_json_port,
        log_dir              => $log_dir,
        username             => $username,
        config_file          => $config_file,
        extra_jvm_opts       => $blazegraph_extra_jvm_opts,
    }

    class { 'wdqs::updater':
        package_dir        => $package_dir,
        data_dir           => $data_dir,
        log_dir            => $log_dir,
        username           => $username,
        logstash_host      => $logstash_host,
        logstash_json_port => $logstash_json_port,
        options            => $updater_options,
        extra_jvm_opts     => $updater_extra_jvm_opts,
        log_sparql         => $log_sparql,
    }

    class { 'wdqs::gui':
        deploy_mode           => $deploy_mode,
        package_dir           => $package_dir,
        data_dir              => $data_dir,
        log_dir               => $log_dir,
        username              => $username,
        enable_ldf            => $enable_ldf,
        max_query_time_millis => $max_query_time_millis,
    }

    class { 'wdqs::crontasks':
        package_dir     => $package_dir,
        data_dir        => $data_dir,
        log_dir         => $log_dir,
        username        => $username,
        load_categories => $load_categories,
        run_tests       => $run_tests,
    }
}
