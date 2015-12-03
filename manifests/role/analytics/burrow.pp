# == role/analytics/burrow.pp
# Role classes for burrow, a consumer offset lag monitoring tool
# for Kafka
class role::analytics::burrow {

    # Include the kafka config role to get all configuration data
    include role::analytics::kafka::config

    # One of the params for Class: burrow is consumer_groups, this is configured
    # through hiera and hence not explicitly passed here
    class { '::burrow':
        zookeeper_hosts    => $role::analytics::kafka::config::zookeeper_hosts,
        zookeeper_path     => $role::analytics::kafka::config::zookeeper_chroot,
        kafka_cluster_name => $role::analytics::kafka::config::kafka_cluster_name,
        kafka_brokers      => $role::analytics::kafka::config::brokers_array,
        smtp_server        => 'mx1001.wikimedia.org',
        from_email         => "burrow@${::fqdn}",
        to_emails          => ['madhuvishy@wikimedia.org', 'otto@wikimedia.org']
    }

    # Burrow has an HTTP REST API on port 8000
    ferm::service { 'burrow':
        proto  => 'tcp',
        port   => '8000',
        srange => '$ALL_NETWORKS',
    }
}
