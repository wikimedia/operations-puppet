define profile::query_service::blazegraph (
    String $username,
    Stdlib::Unixpath $package_dir,
    Stdlib::Unixpath $data_dir,
    Stdlib::Unixpath $log_dir,
    String $deploy_name,
    Stdlib::Port $logstash_logback_port,
    String $heap_size,
    Boolean $use_deployed_config,
    Array[String] $options,
    Array[String] $extra_jvm_opts,
    Array[String] $prometheus_nodes,
    String $contact_groups,
    Boolean $monitoring_enabled,
    Stdlib::Port $nginx_port,
    Stdlib::Port $blazegraph_port,
    Stdlib::Port $prometheus_port,
    Stdlib::Port $prometheus_agent_port,
    String $config_file_name,
    String $prefixes_file,
    Optional[String] $sparql_query_stream,
    Optional[String] $event_service_endpoint,
    Boolean $use_geospatial,
    String $journal,
    String $blazegraph_main_ns,
    String $federation_user_agent,
    String $instance_name = $title,
    Optional[Query_service::OAuthSettings] $oauth_settings = undef,

) {
    require ::profile::query_service::common

    if $sparql_query_stream and !$event_service_endpoint {
        fail('profile::query_service::event_service_endpoint must be provided when profile::query_service::sparql_query_stream is set')
    }

    $prometheus_agent_path = '/usr/share/java/prometheus/jmx_prometheus_javaagent.jar'
    $default_extra_jvm_opts = [
        '-XX:+UseNUMA',
        '-XX:+UnlockExperimentalVMOptions',
        '-XX:G1NewSizePercent=20',
        '-XX:+ParallelRefProcEnabled',
    ]

    $event_service_jvm_opts = $sparql_query_stream ? {
        default => [
            "-Dwdqs.event-sender-filter.event-gate-endpoint=${event_service_endpoint}",
            "-Dwdqs.event-sender-filter.event-gate-sparql-query-stream=${sparql_query_stream}"
        ],
        undef   => []
    }

    $prometheus_agent_config = "/etc/${deploy_name}/${instance_name}-prometheus-jmx.yaml"
    profile::prometheus::jmx_exporter { $instance_name:
        hostname         => $::hostname,
        port             => $prometheus_agent_port,
        prometheus_nodes => $prometheus_nodes,
        config_file      => $prometheus_agent_config,
        source           => 'puppet:///modules/profile/query_service/blazegraph-prometheus-jmx.yaml',
        before           => Service[$instance_name],
    }

    prometheus::blazegraph_exporter { $instance_name:
        nginx_port         => $nginx_port,
        blazegraph_port    => $blazegraph_port,
        prometheus_port    => $prometheus_port,
        prometheus_nodes   => $prometheus_nodes,
        blazegraph_main_ns => $blazegraph_main_ns,
    }

    query_service::blazegraph { $instance_name:
        journal               => $journal,
        package_dir           => $package_dir,
        data_dir              => $data_dir,
        logstash_logback_port => $logstash_logback_port,
        log_dir               => $log_dir,
        deploy_name           => $deploy_name,
        username              => $username,
        options               => $options,
        use_deployed_config   => $use_deployed_config,
        port                  => $blazegraph_port,
        config_file_name      => $config_file_name,
        heap_size             => $heap_size,
        extra_jvm_opts        => $default_extra_jvm_opts + $event_service_jvm_opts + $extra_jvm_opts + "-javaagent:${prometheus_agent_path}=${prometheus_agent_port}:${prometheus_agent_config}",
        use_geospatial        => $use_geospatial,
        oauth_settings        => $oauth_settings,
        blazegraph_main_ns    => $blazegraph_main_ns,
        prefixes_file         => $prefixes_file,
        federation_user_agent => $federation_user_agent
    }

    if $monitoring_enabled {
        query_service::monitor::blazegraph_instance { $instance_name:
            username        => $username,
            contact_groups  => $contact_groups,
            port            => $blazegraph_port,
            prometheus_port => $prometheus_port,
        }
    }
}
