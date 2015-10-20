# == role/analytics/burrow.pp
# Role classes for burrow, a consumer offset lag monitoring tool
# for Kafka
class role::analytics::burrow {

    # Include the kafka config role to get all configuration data
    include role::analytics::kafka::config

    # One of the params for Class: burrow is consumer_groups, this is configured
    # through hiera and hence not explicitly passed here
    class {'::burrow':
        ensure             => 'present',
        client_id          => 'burrow-client-00',
        zk_hosts           => $role::analytics::kafka::config::zookeeper_hosts,
        zk_path            => $role::analytics::kafka::config::zookeeper_chroot,
        kafka_cluster_name => $role::analytics::kafka::config::kafka_cluster_name,
        kafka_brokers      => $role::analytics::kafka::config::brokers_array,
        smtp_server        => 'polonium.wikimedia.org',
        from_email         => "burrow@${::fqdn}",
        to_emails          => 'madhuvishy@wikimedia.org, otto@wikimedia.org',
    }
}
