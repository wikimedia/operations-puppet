# Class: profile::kafka::broker::monitoring
#
# Sets up Prometheus based monitoring and icinga alerts.
#
# [*is_critical]
#   Whether or not to generate critical alerts.
#   Hiera: profile::kafka::broker::monitoring::is_critical

class profile::kafka::broker::monitoring (
    Array[Stdlib::Host] $prometheus_nodes = lookup('prometheus_nodes'),
    String $kafka_cluster_name            = lookup('profile::kafka::broker::kafka_cluster_name'),
    Boolean $is_critical                  = lookup('profile::kafka::broker::monitoring::is_critical', {'default_value' => false}),
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
        hostname                 => $::hostname,
        port                     => $prometheus_jmx_exporter_port,
        prometheus_nodes         => $prometheus_nodes,
        # Allow each kafka broker node access to other broker's prometheus JMX exporter port.
        # This will help us use kafka-tools to calculate partition reassignements
        # based on broker metrics like partition sizes, etc.
        # https://github.com/linkedin/kafka-tools/tree/master/kafka/tools/assigner
        extra_ferm_allowed_nodes => $config['brokers']['array'],
        labels                   => {'kafka_cluster' => $kafka_cluster},
        config_file              => $jmx_exporter_config_file,
        config_dir               => $config_dir,
        source                   => 'puppet:///modules/profile/kafka/broker_prometheus_jmx_exporter.yaml',
    }

    ### Icinga alerts
    # Generate icinga alert if Kafka Broker Server is not running.
    nrpe::monitor_service { 'kafka':
        description  => 'Kafka Broker Server',
        nrpe_command => '/usr/lib/nagios/plugins/check_procs -c 1:1 -C java -a "Kafka /etc/kafka/server.properties"',
        critical     => $is_critical,
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


    # Alert if replica lag is increasing (positive slope) for multiple after multiple retries.
    monitoring::check_prometheus { 'kafka_broker_replica_lag_increasing':
        description     => 'Kafka Broker Replica Max Lag is increasing',
        dashboard_links => ["https://grafana.wikimedia.org/dashboard/db/kafka?panelId=16&fullscreen&orgId=1&var-datasource=${::site} prometheus/ops&var-kafka_cluster=${kafka_cluster}&var-kafka_broker=${::hostname}"],
        query           => "scalar(deriv(kafka_server_ReplicaFetcherManager_MaxLag{${prometheus_labels}}[5m]))",
        # I really just want an alert if lag slope is positive over a time range, but
        # check_prometheus_metric.py requires that critical is > warning if method is 'gt'.
        warning         => 0.0,
        critical        => 0.1,
        method          => 'gt',
        # We only want to alert if lag is steadily increasing.  6 retries over 5 minutes should
        # alert if is increasing (positive slope) for at least 30 minutes.
        retries         => 6,
        retry_interval  => 5,
        prometheus_url  => "http://prometheus.svc.${::site}.wmnet/ops",
        notes_link      => 'https://wikitech.wikimedia.org/wiki/Kafka/Administration',
    }
}
