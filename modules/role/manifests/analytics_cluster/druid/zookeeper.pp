class role::analytics_cluster::druid::zookeeper {
    include profile::zookeeper::server
    include profile::zookeeper::firewall
}