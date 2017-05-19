class role::analytics_cluster::druid::zookeeper {
    include profile::zookeeper::client
    include profile::zookeeper::server
}