# == Class role::kafka::analytics::burrow
# Role classes for burrow, a consumer offset lag monitoring tool
# for Kafka.
#
class role::kafka::analytics::burrow {

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
    }

    # Burrow has an HTTP REST API on port 8000
    ferm::service { 'burrow':
        proto  => 'tcp',
        port   => '8000',
        srange => '$DOMAIN_NETWORKS',
    }
}
