# Class: profile::kafka::broker::monitoring
#
# Sets up Prometheus based monitoring and icinga alerts.
#
# [*replica_maxlag_warning*]
#   Max messages a replica can lag before a warning alert is generated.
#   Hiera: profile::kafka::broker::replica_maxlag_warning
#
# [*replica_maxlag_critical*]
#   Mac messages a replica can lag before a critical alert is generated.
#   Hiera: profile::kafka::broker::replica_maxlag_critical
#
class profile::kafka::broker::monitoring (
    $prometheus_nodes        = hiera('prometheus_nodes'),
    $kafka_cluster_name      = hiera('profile::kafka::broker::kafka_cluster_name'),
    $replica_maxlag_warning  = hiera('profile::kafka::broker::monitoring::replica_maxlag_warning', 10000),
    $replica_maxlag_critical = hiera('profile::kafka::broker::monitoring::replica_maxlag_critical', 100000),
) {
    # Get fully qualified Kafka cluster name
    $config        = kafka_config($kafka_cluster_name)
    $kafka_cluster = $config['name']

    $prometheus_jmx_exporter_port = 7800
    $config_dir                   = '/etc/prometheus'
    $jmx_exporter_config_file     = "${config_dir}/kafka_broker_prometheus_jmx_exporter.yaml"

    # Use this in your JAVA_OPTS you pass to the Kafka  broker process
    $java_opts = "-javaagent:/usr/share/java/prometheus/jmx_prometheus_javaagent.jar=${::ipaddress}:${prometheus_jmx_exporter_port}:${jmx_exporter_config_file}"

    # Declare a prometheus jmx_exporter instance.
    # This will render the config file, declare the jmx_exporter_instance,
    # and configure ferm.
    profile::prometheus::jmx_exporter { "kafka_broker_${::hostname}":
        hostname         => $::hostname,
        port             => $prometheus_jmx_exporter_port,
        prometheus_nodes => $prometheus_nodes,
        labels           => {'kafka_cluster' => $kafka_cluster},
        config_file      => $jmx_exporter_config_file,
        config_dir       => $config_dir,
        source           => 'puppet:///modules/profile/kafka/broker_prometheus_jmx_exporter.yaml',
    }

    ### Icinga alerts
    # Generate icinga alert if Kafka Broker Server is not running.
    nrpe::monitor_service { 'kafka':
        description  => 'Kafka Broker Server',
        nrpe_command => '/usr/lib/nagios/plugins/check_procs -c 1:1 -C java -a "Kafka /etc/kafka/server.properties"',
        critical     => true,
        notes_url    => 'https://wikitech.wikimedia.org/wiki/Kafka/Administration',
    }

    # Prometheus labels for this Kafka Broker instance
    $prometheus_labels = "kafka_cluster=\"${kafka_cluster}\",instance=\"${::hostname}:${prometheus_jmx_exporter_port}\""

    # Alert if there are consistent under replicated partitions in the last 10 minutes.
    monitoring::check_prometheus { 'kafka_broker_under_replicated_partitions':
        description     => 'Kafka Broker Under Replicated Partitions',
        dashboard_links => ["https://grafana.wikimedia.org/dashboard/db/kafka?panelId=29&fullscreen&orgId=1&var-datasource=${::site} prometheus/ops&var-kafka_cluster=${kafka_cluster}&var-kafka_broker=${::hostname}"],
        query           => "scalar(min_over_time(kafka_server_ReplicaManager_UnderReplicatedPartitions{${prometheus_labels}}[10m]))",
        warning         => 1,
        critical        => 10,
        prometheus_url  => "http://prometheus.svc.${::site}.wmnet/ops",
        notes_link      => 'https://wikitech.wikimedia.org/wiki/Kafka/Administration',
    }

    # Alert on the average max replica lag over the last 30 minutes.
    monitoring::check_prometheus { 'kafka_broker_replica_max_lag':
        description     => 'Kafka Broker Replica Max Lag',
        dashboard_links => ["https://grafana.wikimedia.org/dashboard/db/kafka?panelId=16&fullscreen&orgId=1&var-datasource=${::site} prometheus/ops&var-kafka_cluster=${kafka_cluster}&var-kafka_broker=${::hostname}"],
        query           => "scalar(avg_over_time(kafka_server_ReplicaFetcherManager_MaxLag{${prometheus_labels}}[30m]))",
        warning         => $replica_maxlag_warning,
        critical        => $replica_maxlag_critical,
        prometheus_url  => "http://prometheus.svc.${::site}.wmnet/ops",
        notes_link      => 'https://wikitech.wikimedia.org/wiki/Kafka/Administration',
    }
}
