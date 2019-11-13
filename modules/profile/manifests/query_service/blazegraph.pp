class profile::query_service::blazegraph(
    Stdlib::Unixpath $package_dir = hiera('profile::query_service::package_dir'),
    Stdlib::Unixpath $data_dir = hiera('profile::query_service::data_dir'),
    Stdlib::Unixpath $log_dir = hiera('profile::query_service::log_dir'),
    String $deploy_name = hiera('profile::query_service::deploy_name'),
    Stdlib::Port $logstash_logback_port = hiera('logstash_logback_port'),
    String $endpoint = hiera('profile::query_service::endpoint'),
    String $heap_size = hiera('profile::query_service::blazegraph_heap_size', '31g'),
    Boolean $use_deployed_config = hiera('profile::query_service::blazegraph_use_deployed_config', false),
    Array[String] $options = hiera('profile::query_service::blazegraph_options'),
    Array[String] $extra_jvm_opts = hiera('profile::query_service::blazegraph_extra_jvm_opts'),
    Array[String] $prometheus_nodes = hiera('prometheus_nodes'),
    String $contact_groups = hiera('contactgroups', 'admins'),
    Integer[0] $lag_warning  = hiera('profile::query_service::lag_warning', 1200),
    Integer[0] $lag_critical = hiera('profile::query_service::lag_critical', 3600),
    Optional[String] $sparql_query_stream = hiera('profile::query_service::sparql_query_stream', undef),
    Optional[String] $event_service_endpoint = hiera('profile::query_service::event_service_endpoint', undef)
) {
    require ::profile::query_service::common

    if $sparql_query_stream and !$event_service_endpoint {
        fail('profile::query_service::event_service_endpoint must be provided when profile::query_service::sparql_query_stream is set')
    }

    $username = 'blazegraph'
    $instance_name = "${deploy_name}-blazegraph"
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

    $prometheus_agent_port_blazegraph = 9102
    $prometheus_agent_config_blazegraph = "/etc/${deploy_name}/${instance_name}-prometheus-jmx.yaml"
    profile::prometheus::jmx_exporter { $instance_name:
        hostname         => $::hostname,
        prometheus_nodes => $prometheus_nodes,
        source           => 'puppet:///modules/profile/query_service/blazegraph-prometheus-jmx.yaml',
        port             => $prometheus_agent_port_blazegraph,
        before           => Service[$instance_name],
        config_file      => $prometheus_agent_config_blazegraph,
    }

    prometheus::blazegraph_exporter { 'wdqs-blazegraph':
        blazegraph_port  => 9999,
        prometheus_port  => 9193,
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
        port                  => 9999,
        config_file_name      => 'RWStore.properties',
        heap_size             => $heap_size,
        extra_jvm_opts        => $default_extra_jvm_opts + $event_service_jvm_opts + $extra_jvm_opts + "-javaagent:${prometheus_agent_path}=${prometheus_agent_port_blazegraph}:${prometheus_agent_config_blazegraph}"
    }

    class { 'query_service::monitor::blazegraph':
        username       => $username,
        contact_groups => $contact_groups,
        lag_warning    => $lag_warning,
        lag_critical   => $lag_critical,
    }

    query_service::monitor::blazegraph_instance { $instance_name:
        username        => $username,
        contact_groups  => $contact_groups,
        port            => 9999,
        prometheus_port => 9193,
    }
}
