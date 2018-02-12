# == define profile::kafka::burrow
#
# Consumer offset lag monitoring tool template for a generic Kafka cluster
#
define profile::kafka::burrow(
    $http_port,
    $consumer_groups,
    $to_emails = ['analytics-alerts@wikimedia.org'],
) {

    $config = kafka_config($title)
    $smtp_server = 'mx1001.wikimedia.org'

    burrow { $title:
        zookeeper_hosts    => $config['zookeeper']['hosts'],
        zookeeper_path     => $config['zookeeper']['chroot'],
        kafka_cluster_name => $config['name'],
        kafka_brokers      => $config['brokers']['array'],
        smtp_server        => $smtp_server,
        from_email         => "burrow@${::fqdn}",
        to_emails          => $to_emails,
        lagcheck_intervals => 100,
        httpserver_port    => $http_port,
        consumer_groups    => $consumer_groups,
    }

    # Burrow offers a HTTP REST API
    ferm::service { "burrow-${title}":
        proto  => 'tcp',
        port   => $http_port,
        srange => '$DOMAIN_NETWORKS',
    }
}
