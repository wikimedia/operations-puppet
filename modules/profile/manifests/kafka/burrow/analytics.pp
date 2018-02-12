# == class profile::kafka::burrow::analytics
#
# Consumer offset lag monitoring tool for the Kafka Analytics cluster
#
class profile::kafka::burrow::analytics(
    $consumer_groups = hiera('profile::kafka::burrow:analytics::consumer_groups'),
    $to_emails       = hiera('profile::kafka::burrow:analytics::to_emails', ['analytics-alerts@wikimedia.org'])
) {

    $analytics_config = kafka_config('analytics')
    $smtp_server = 'mx1001.wikimedia.org'
    $analytics_port = 8000

    burrow { 'analytics':
        zookeeper_hosts    => $analytics_config['zookeeper']['hosts'],
        zookeeper_path     => $analytics_config['zookeeper']['chroot'],
        kafka_cluster_name => $analytics_config['name'],
        kafka_brokers      => $analytics_config['brokers']['array'],
        smtp_server        => $smtp_server,
        from_email         => "burrow@${::fqdn}",
        to_emails          => $to_emails,
        lagcheck_intervals => 100,
        httpserver_port    => $analytics_port,
        consumer_groups    => $consumer_groups,
    }

    # Burrow offers a HTTP REST API
    ferm::service { 'burrow-analytics':
        proto  => 'tcp',
        port   => $analytics_port,
        srange => '$DOMAIN_NETWORKS',
    }
}
