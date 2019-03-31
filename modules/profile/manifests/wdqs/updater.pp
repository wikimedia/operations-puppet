class profile::wdqs::updater (
    String $options = hiera('profile::wdqs::updater_options', '-n wdq'),
    String $logstash_host = hiera('logstash_host'),
    Wmflib::IpPort $logstash_json_port = hiera('logstash_json_lines_port'),
    Stdlib::Unixpath $package_dir = hiera('profile::wdqs::package_dir', '/srv/deployment/wdqs/wdqs'),
    Stdlib::Unixpath $data_dir = hiera('profile::wdqs::data_dir', '/srv/wdqs'),
    Stdlib::Unixpath $log_dir = hiera('profile::wdqs::log_dir', '/var/log/wdqs'),
    Boolean $log_sparql = hiera('profile::wdqs::log_sparql', false),
    Array[String] $prometheus_nodes = hiera('prometheus_nodes'),
    Boolean $use_kafka_for_updates = hiera('profile::wdqs::use_kafka_for_updates', true),
    String $kafka_options = hiera('profile::wdqs::kafka_updater_options', '-b 700'),
    String $kafka_reporting_topic = hiera('profile::wdqs::kafka_reporting_topic', 'eqiad.mediawiki.revision-create'),
    Array[String] $cluster_names = hiera('profile::wdqs::cluster_names', [ 'eqiad', 'codfw' ]),
    String $rc_options = hiera('profile::wdqs::rc_updater_options', '-b 500 -T 1200'),
    Boolean $fetch_constraints = hiera('profile::wdqs::fetch_constraints', true),
    Boolean $enable_rdf_dump = hiera('profile::wdqs::enable_rdf_dump', false),
    Boolean $use_revisions = hiera('profile::wdqs::use_revisions', false),
) {
    require ::profile::wdqs::common

    $username = 'blazegraph'
    $prometheus_agent_path = '/usr/share/java/prometheus/jmx_prometheus_javaagent.jar'
    $prometheus_agent_port = '9101'
    $prometheus_agent_config = '/etc/wdqs/wdqs-updater-prometheus-jmx.yaml'
    profile::prometheus::jmx_exporter { 'wdqs_updater':
        hostname         => $::hostname,
        port             => $prometheus_agent_port,
        prometheus_nodes => $prometheus_nodes,
        config_file      => $prometheus_agent_config,
        source           => 'puppet:///modules/profile/wdqs/wdqs-updater-prometheus-jmx.yaml',
        before           => Service['wdqs-updater'],
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

    # 0 - Main, 120 - Property, 146 - Lexeme
    $extra_updater_options = $poller_options + $fetch_constraints_options + $dump_options + $revision_options + [ '--entityNamespaces', '0,120,146' ]

    class { 'wdqs::updater':
        package_dir        => $package_dir,
        data_dir           => $data_dir,
        log_dir            => $log_dir,
        username           => $username,
        logstash_host      => $logstash_host,
        logstash_json_port => $logstash_json_port,
        options            => split($options, ' ') + ['--'] + $extra_updater_options,
        extra_jvm_opts     => $default_jvm_options + $kafka_jvm_opts,
        log_sparql         => $log_sparql,
    }

    class { 'wdqs::monitor::updater':
        username => $username,
    }

}
