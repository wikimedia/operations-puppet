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
    $cluster                 = hiera('cluster'),
    $prometheus_nodes        = hiera('prometheus_nodes'),
    $replica_maxlag_warning  = hiera('profile::kafka::broker::monitoring::replica_maxlag_warning'),
    $replica_maxlag_critical = hiera('profile::kafka::broker::monitoring::replica_maxlag_critical'),
) {
    $prometheus_jmx_exporter_port = 7800
    $jmx_exporter_config_file = '/etc/kafka/broker_prometheus_jmx_exporter.yaml'

    # Use this in your JAVA_OPTS you pass to the Kafka  broker process
    $java_opts = "-javaagent:/usr/share/java/prometheus/jmx_prometheus_javaagent.jar=${::ipaddress}:${prometheus_jmx_exporter_port}:${jmx_exporter_config_file}"

    # Declare a prometheus jmx_exporter instance.
    # This will render the config file, declare the jmx_exporter_instance,
    # and configure ferm.
    profile::prometheus::jmx_exporter { "kafka_broker_${::hostname}":
        hostname         => $::hostname,
        port             => $prometheus_jmx_exporter_port,
        prometheus_nodes => $prometheus_nodes,
        config_file      => $jmx_exporter_config_file,
        source           => 'puppet:///modules/profile/kafka/broker_prometheus_jmx_exporter.yaml',
    }

    ### Icinga alerts
    # Generate icinga alert if Kafka Broker Server is not running.
    nrpe::monitor_service { 'kafka':
        description  => 'Kafka Broker Server',
        nrpe_command => '/usr/lib/nagios/plugins/check_procs -c 1:1 -C java -a "Kafka /etc/kafka/server.properties"',
        critical     => true,
    }

    # Prometheus labels for this Kafka Broker instance
    $prometheus_labels = "cluster=\"${cluster}\",instance=\"${::hostname}:${prometheus_jmx_exporter_port}\",job=\"jmx_kafka\""

    # Alert on the average number of under replicated partitions over the last 30 minutes.
    monitoring::check_prometheus { 'kafka_broker_under_replicated_partitions':
        description     => 'Kafka Broker Under Replicated Partitions',
        dashboard_links => ["https://grafana.wikimedia.org/dashboard/db/prometheus-kafka?panelId=29&fullscreen&orgId=1&var-datasource=${::site} prometheus/ops&var-cluster=${cluster}&var-kafka_brokers=${::hostname}"],
        query           => "scalar(avg_over_time(kafka_server_ReplicaManager_UnderReplicatedPartitions{${prometheus_labels}}[30m]))",
        warning         => 5,
        critical        => 10,
        prometheus_url  => "http://prometheus.svc.${::site}.wmnet/ops",
    }

    # Alert on the average max replica lag over the last 30 minutes.
    monitoring::check_prometheus { 'kafka_broker_replica_max_lag':
        description     => 'Kafka Broker Replica Max Lag',
        dashboard_links => ["https://grafana.wikimedia.org/dashboard/db/prometheus-kafka?panelId=16&fullscreen&orgId=1&var-datasource=${::site} prometheus/ops&var-cluster=${cluster}&var-kafka_brokers=${::hostname}"],
        query           => "scalar(avg_over_time(kafka_server_ReplicaFetcherManager_MaxLag{${prometheus_labels}}[30m]))",
        warning         => $replica_maxlag_warning,
        critical        => $replica_maxlag_critical,
        prometheus_url  => "http://prometheus.svc.${::site}.wmnet/ops",
    }
}
