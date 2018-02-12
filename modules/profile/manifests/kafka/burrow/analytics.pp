# == Class profile::kafka::burrow::analytics
#
# Role classes for burrow, a consumer offset lag monitoring tool
# for Kafka.
#
class profile::kafka::burrow::analytics {

    $config = kafka_config('analytics')

    # One of the params for Class: burrow is consumer_groups, this is configured
    # through hiera and hence not explicitly passed here
    class { '::burrow':
        zookeeper_hosts    => $config['zookeeper']['hosts'],
        zookeeper_path     => $config['zookeeper']['chroot'],
        kafka_cluster_name => $config['name'],
        kafka_brokers      => $config['brokers']['array'],
        smtp_server        => 'mx1001.wikimedia.org',
        from_email         => "burrow@${::fqdn}",
        to_emails          => ['analytics-alerts@wikimedia.org'],
        httpserver_port    => 8000,
    }

    # Burrow offers an HTTP REST API
    ferm::service { 'burrow-analytics':
        proto  => 'tcp',
        port   => 8000,
        srange => '$DOMAIN_NETWORKS',
    }
}
