class profile::query_service::categories(
    Stdlib::Unixpath $package_dir = hiera('profile::wdqs::package_dir', '/srv/deployment/wdqs/wdqs'),
    Stdlib::Unixpath $data_dir = hiera('profile::wdqs::data_dir', '/srv/wdqs'),
    Stdlib::Unixpath $log_dir = hiera('profile::wdqs::log_dir', '/var/log/wdqs'),
    String $deploy_name = hiera('profile::wdqs::deploy_name', 'wdqs'),
    Stdlib::Port $logstash_logback_port = hiera('logstash_logback_port'),
    Boolean $use_deployed_config = hiera('profile::wdqs::blazegraph_use_deployed_config', false),
    Array[String] $options = hiera('profile::wdqs::blazegraph_options'),
    Array[String] $extra_jvm_opts = hiera('profile::wdqs::blazegraph_extra_jvm_opts'),
    Array[String] $prometheus_nodes = hiera('prometheus_nodes'),
    String $contact_groups = hiera('contactgroups', 'admins'),
) {
    require ::profile::query_service::common

    $username = 'blazegraph'
    $instance_name = "${deploy_name}-categories"
    $prometheus_agent_path = '/usr/share/java/prometheus/jmx_prometheus_javaagent.jar'
    $default_extra_jvm_opts = [
        '-XX:+UseNUMA',
        '-XX:+UnlockExperimentalVMOptions',
        '-XX:G1NewSizePercent=20',
        '-XX:+ParallelRefProcEnabled',
    ]

    $prometheus_agent_port_categories = 9103
    $prometheus_agent_config_categories = "/etc/${deploy_name}/${instance_name}-prometheus-jmx.yaml"
    profile::prometheus::jmx_exporter { $instance_name:
        hostname         => $::hostname,
        prometheus_nodes => $prometheus_nodes,
        source           => 'puppet:///modules/profile/query_service/blazegraph-prometheus-jmx.yaml',
        port             => $prometheus_agent_port_categories,
        before           => Service[$instance_name],
        config_file      => $prometheus_agent_config_categories,
    }

    prometheus::blazegraph_exporter { 'wdqs-categories':
        blazegraph_port  => 9990,
        prometheus_port  => 9194,
        prometheus_nodes => $prometheus_nodes,
    }

    query_service::blazegraph { $instance_name:
        package_dir           => $package_dir,
        data_dir              => $data_dir,
        logstash_logback_port => $logstash_logback_port,
        log_dir               => $log_dir,
        deploy_name           => $deploy_name,
        username              => $username,
        options               => $options,
        use_deployed_config   => $use_deployed_config,
        port                  => 9990,
        config_file_name      => 'RWStore.categories.properties',
        heap_size             => '8g',
        extra_jvm_opts        => $default_extra_jvm_opts + $extra_jvm_opts +  "-javaagent:${prometheus_agent_path}=${prometheus_agent_port_categories}:${prometheus_agent_config_categories}"
    }

    class { 'query_service::monitor::categories':   }

    query_service::monitor::blazegraph_instance { $instance_name:
        username        => $username,
        contact_groups  => $contact_groups,
        port            => 9990,
        prometheus_port => 9194,
    }
}
