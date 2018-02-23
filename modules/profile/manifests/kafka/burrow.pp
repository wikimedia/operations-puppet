# == define profile::kafka::burrow
#
# Consumer offset lag monitoring tool template for a generic Kafka cluster
#
define profile::kafka::burrow(
    $prometheus_nodes,
    $monitoring_config,
    $to_emails = [],
) {
    $config = kafka_config($title)
    $smtp_server = 'mx1001.wikimedia.org'
    $kafka_cluster_name = $config['name']

    $consumer_groups = monitoring_config[$title]['consumer_groups']
    $burrow_http_port = monitoring_config[$title]['burrow_port']
    $prometheus_burrow_http_port = monitoring_config[$title]['burrow_exporter_port']
    $to_emails = monitoring_config[$title]['to_emails']

    burrow { $kafka_cluster_name:
        zookeeper_hosts    => $config['zookeeper']['hosts'],
        zookeeper_path     => $config['zookeeper']['chroot'],
        kafka_cluster_name => $kafka_cluster_name,
        kafka_brokers      => $config['brokers']['array'],
        smtp_server        => $smtp_server,
        from_email         => "burrow@${::fqdn}",
        to_emails          => $to_emails,
        lagcheck_intervals => 100,
        httpserver_port    => $burrow_http_port,
        consumer_groups    => $consumer_groups,
    }

    profile::prometheus::burrow_exporter { $kafka_cluster_name:
        burrow_addr      => "localhost:${burrow_http_port}",
        port             => $prometheus_burrow_http_port,
        prometheus_nodes => $prometheus_nodes,
    }

    # Burrow offers a HTTP REST API
    ferm::service { "burrow-${kafka_cluster_name}":
        proto  => 'tcp',
        port   => $burrow_http_port,
        srange => '$DOMAIN_NETWORKS',
    }
}
