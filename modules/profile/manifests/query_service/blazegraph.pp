# SPDX-License-Identifier: Apache-2.0
define profile::query_service::blazegraph (
    String $username,
    Stdlib::Unixpath $package_dir,
    Stdlib::Unixpath $data_dir,
    Stdlib::Unixpath $log_dir,
    String $deploy_name,
    Stdlib::Port $logstash_logback_port,
    String $heap_size,
    Boolean $use_deployed_config,
    Array[String] $extra_jvm_opts,
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
    Boolean $use_oauth = false,
    Optional[String] $jvmquake_options = undef,
    Optional[Integer] $jvmquake_warn_threshold = undef,
    String $jvmquake_warn_file = "/tmp/jvmquake_warn_gc_${title}",
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

    if $jvmquake_warn_threshold and $jvmquake_options {
        $jvmquake_combined_options = "${jvmquake_options},warn=${jvmquake_warn_threshold},touch=${jvmquake_warn_file}"
        prometheus::node_file_flag { "jvmquake_${instance_name}":
          paths   => [ $jvmquake_warn_file ],
          outfile => "/var/lib/prometheus/node.d/jvmquake_${instance_name}_file_flag.prom",
          metric  => "jvmquake_${instance_name}_warn_gc",
        }
    } else {
        $jvmquake_combined_options = $jvmquake_options
    }

    $jvmquake_jvm_opts = $jvmquake_combined_options ? {
        default => [
            "-agentpath:/usr/lib/libjvmquake.so=${jvmquake_combined_options}",
        ],
        undef   => []
    }

    if $jvmquake_jvm_opts != [] {
        ensure_packages('jvmquake')
    }

    $prometheus_agent_config = "/etc/${deploy_name}/${instance_name}-prometheus-jmx.yaml"

    $prometheus_jvm_opts = ["-javaagent:${prometheus_agent_path}=${prometheus_agent_port}:${prometheus_agent_config}"]

    profile::prometheus::jmx_exporter { $instance_name:
        hostname    => $::hostname,
        port        => $prometheus_agent_port,
        config_file => $prometheus_agent_config,
        source      => 'puppet:///modules/profile/query_service/blazegraph-prometheus-jmx.yaml',
        before      => Service[$instance_name],
    }

    prometheus::blazegraph_exporter { $instance_name:
        nginx_port         => $nginx_port,
        blazegraph_port    => $blazegraph_port,
        prometheus_port    => $prometheus_port,
        blazegraph_main_ns => $blazegraph_main_ns,
        # The auth flow blocks the exporter from talking through nginx
        collect_via_nginx  => !$use_oauth,
    }

    query_service::blazegraph { $instance_name:
        journal               => $journal,
        package_dir           => $package_dir,
        data_dir              => $data_dir,
        logstash_logback_port => $logstash_logback_port,
        log_dir               => $log_dir,
        deploy_name           => $deploy_name,
        username              => $username,
        use_deployed_config   => $use_deployed_config,
        port                  => $blazegraph_port,
        config_file_name      => $config_file_name,
        heap_size             => $heap_size,
        extra_jvm_opts        => $default_extra_jvm_opts
                                    + $event_service_jvm_opts
                                    + $extra_jvm_opts
                                    + $prometheus_jvm_opts
                                    + $jvmquake_jvm_opts,
        use_geospatial        => $use_geospatial,
        blazegraph_main_ns    => $blazegraph_main_ns,
        prefixes_file         => $prefixes_file,
        federation_user_agent => $federation_user_agent,
        use_oauth             => $use_oauth,
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
