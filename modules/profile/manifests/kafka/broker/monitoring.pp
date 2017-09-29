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
    ### Expose Kafka Broker JMX metrics to Prometheus
    require_package('prometheus-jmx-exporter')

    $prometheus_jmx_exporter_port = 7800
    $jmx_exporter_config_file = '/etc/kafka/broker_prometheus_jmx_exporter.yaml'

    # Use this in your JAVA_OPTS you pass to the Kafka  broker process
    $java_opts = "-javaagent:/usr/share/java/prometheus/jmx_prometheus_javaagent.jar=${::ipaddress}:${prometheus_jmx_exporter_port}:${jmx_exporter_config_file}"

    # Create the Prometheus JMX Exporter configuration
    file { $jmx_exporter_config_file:
        ensure  => present,
        source  => 'puppet:///modules/profile/kafka/broker_prometheus_jmx_exporter.yaml',
        owner   => 'kafka',
        group   => 'kafka',
        mode    => '0400',
        # Require this to make sure that kafka user and group are already created.
        require => Class['::confluent::kafka::broker'],
    }

    # Allow automatic generation of config on the Prometheus master
    prometheus::jmx_exporter_instance { $::hostname:
        address => $::ipaddress,
        port    => $prometheus_jmx_exporter_port,
    }

    $prometheus_nodes_ferm = join($prometheus_nodes, ' ')
    ferm::service { 'kafka-broker-jmx_exporter':
        proto  => 'tcp',
        port   => '7800',
        srange => "@resolve((${prometheus_nodes_ferm}))",
    }


    ### Icinga alerts
    # Generate icinga alert if Kafka Broker Server is not running.
    nrpe::monitor_service { 'kafka':
        description  => 'Kafka Broker Server',
        nrpe_command => '/usr/lib/nagios/plugins/check_procs -c 1:1 -C java -a "Kafka /etc/kafka/server.properties"',
        critical     => true,
    }

    # Prometheus labels for this Kafka Broker instance
    $prometheus_labels = "cluster=${cluster},instance=${::hostname}:${prometheus_jmx_exporter_port},job=jmx_kafka"

    # Alert on the average number of under replicated partitions over the last 30 minutes.
    # https://grafana.wikimedia.org/dashboard/db/prometheus-kafka?panelId=29&fullscreen
    monitoring::check_prometheus { 'kafka_broker_under_replicated_partitions':
        description    => 'Kafka Broker Under Replicated Partitions',
        query          => "scalar(avg_over_time(kafka_server_replicamanager_underreplicatedpartitions{${prometheus_labels}}[30m]))",
        warning        => 5,
        critical       => 10,
        prometheus_url => "http://prometheus.svc.${::site}.wmnet/ops",
    }

    # Alert on the average max replica lag over the last 30 minutes.
    # https://grafana.wikimedia.org/dashboard/db/prometheus-kafka?panelId=16&fullscreen
    monitoring::check_prometheus { 'kafka_broker_replica_max_lag':
        description    => 'Kafka Broker Replica Max Lag',
        query          => "scalar(avg_over_time(kafka_server_replicafetchermanager_maxlag{${prometheus_labels}}[30m]))",
        warning        => $replica_maxlag_warning,
        critical       => $replica_maxlag_critical,
        prometheus_url => "http://prometheus.svc.${::site}.wmnet/ops",
    }
}