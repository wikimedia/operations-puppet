# == role/analytics/burrow.pp
# Role classes for burrow, a consumer offset lag monitoring tool
# for Kafka
class role::analytics::burrow {

    # Include the kafka config role to get all configuration data
    include role::kafka::analytics::config

    # One of the params for Class: burrow is consumer_groups, this is configured
    # through hiera and hence not explicitly passed here
    class { '::burrow':
        zookeeper_hosts    => $role::kafka::analytics::config::zookeeper_hosts,
        zookeeper_path     => $role::kafka::analytics::config::zookeeper_chroot,
        kafka_cluster_name => $role::kafka::analytics::config::cluster_name,
        kafka_brokers      => $role::kafka::analytics::config::brokers_array,
        smtp_server        => 'mx1001.wikimedia.org',
        from_email         => "burrow@${::fqdn}",
        to_emails          => ['analytics-alerts@wikimedia.org']
    }

    # Burrow has an HTTP REST API on port 8000
    ferm::service { 'burrow':
        proto  => 'tcp',
        port   => '8000',
        srange => '$ALL_NETWORKS',
    }
}
