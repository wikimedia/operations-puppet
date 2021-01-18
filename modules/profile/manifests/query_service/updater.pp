class profile::query_service::updater (
    String $username = lookup('profile::query_service::username'),
    String $options = lookup('profile::query_service::updater_options'),
    Boolean $async_import = lookup('profile::query_service::async_import', {'default_value' => false}),
    Stdlib::Port $logstash_logback_port = lookup('logstash_logback_port'),
    Stdlib::Unixpath $package_dir = lookup('profile::query_service::package_dir'),
    Stdlib::Unixpath $data_dir = lookup('profile::query_service::data_dir'),
    Stdlib::Unixpath $log_dir = lookup('profile::query_service::log_dir'),
    String $deploy_name = lookup('profile::query_service::deploy_name'),
    Boolean $log_sparql = lookup('profile::query_service::log_sparql', {'default_value' => false}),
    Array[String] $prometheus_nodes = lookup('prometheus_nodes'),
    Boolean $use_kafka_for_updates = lookup('profile::query_service::use_kafka_for_updates', {'default_value' => true}),
    String $kafka_options = lookup('profile::query_service::kafka_updater_options', {'default_value' => '-b 700'}),
    String $kafka_reporting_topic = lookup('profile::query_service::kafka_reporting_topic', {'default_value' => 'eqiad.mediawiki.revision-create'}),
    Array[String] $cluster_names = lookup('profile::query_service::cluster_names', {'default_value' => [ 'eqiad', 'codfw' ]}),
    String $rc_options = lookup('profile::query_service::rc_updater_options', {'default_value' => '-b 500 -T 1200'}),
    Boolean $fetch_constraints = lookup('profile::query_service::fetch_constraints', {'default_value' => true}),
    Boolean $enable_rdf_dump = lookup('profile::query_service::enable_rdf_dump', {'default_value' => false}),
    Boolean $use_revisions = lookup('profile::query_service::use_revisions'),
) {
    require ::profile::query_service::common

    $instance_name = "${deploy_name}-updater"
    $prometheus_agent_path = '/usr/share/java/prometheus/jmx_prometheus_javaagent.jar'
    $prometheus_agent_port = 9101
    $prometheus_agent_config = "/etc/${deploy_name}/${instance_name}-prometheus-jmx.yaml"
    profile::prometheus::jmx_exporter { $instance_name:
        hostname         => $::hostname,
        port             => $prometheus_agent_port,
        prometheus_nodes => $prometheus_nodes,
        config_file      => $prometheus_agent_config,
        source           => 'puppet:///modules/profile/query_service/updater-prometheus-jmx.yaml',
        before           => Service[$instance_name],
    }

    $default_jvm_options = ['-XX:+UseNUMA', "-javaagent:${prometheus_agent_path}=${prometheus_agent_port}:${prometheus_agent_config}"]

    if $use_kafka_for_updates {
        $kafka_brokers = kafka_config('main')['brokers']['string']
        $base_kafka_options = [ '--kafka', $kafka_brokers, '--consumer', $::hostname, $kafka_options ]
        $joined_cluster_names = join($cluster_names, ',')

        $poller_options = count($cluster_names) ? {
            0       => $base_kafka_options,
            default => $base_kafka_options + [ '--clusters', $joined_cluster_names ],
        }
        $kafka_jvm_opts = [ "-Dorg.wikidata.query.rdf.tool.change.KafkaPoller.reportingTopic=${kafka_reporting_topic}" ]
    } else {
        $poller_options = [ $rc_options ]
        $kafka_jvm_opts = []
    }

    $fetch_constraints_options = $fetch_constraints ? {
        true    => [ '--constraints' ],
        default => [],
    }
    $dump_options = $enable_rdf_dump ? {
        true    => [ '--dumpDir', "${data_dir}/dumps" ],
        default => [],
    }
    $revision_options = $use_revisions ? {
        # TODO: make revision cutoff configurable?
        true    => [ '--oldRevision', '3' ],
        default => [],
    }

    $async_import_option = $async_import ? {
        true    => ['--import-async'],
        default => [],
    }

    # 0 - Main, 120 - Property, 146 - Lexeme
    $extra_updater_options = $async_import_option + $poller_options + $fetch_constraints_options + $dump_options + $revision_options + [ '--entityNamespaces', '0,120,146' ]

    class { 'query_service::updater':
        package_dir            => $package_dir,
        data_dir               => $data_dir,
        log_dir                => $log_dir,
        deploy_name            => $deploy_name,
        username               => $username,
        logstash_logback_port  => $logstash_logback_port,
        options                => split($options, ' ') + ['--'] + $extra_updater_options,
        extra_jvm_opts         => $default_jvm_options + $kafka_jvm_opts,
        updater_startup_script => 'runUpdate.sh',
        updater_service_desc   => 'Query Service Updater',
        log_sparql             => $log_sparql,
    }

    class { 'query_service::monitor::updater':
        username           => $username,
        updater_main_class => 'org.wikidata.query.rdf.tool.Update',
    }

}
