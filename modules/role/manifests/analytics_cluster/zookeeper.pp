class role::analytics_cluster::zookeeper {
    system::role { 'analytics_cluster::zookeeper':
        description => 'Analytics Zookeeper cluster node'
    }
    include ::profile::standard
    include ::profile::base::firewall

    include ::profile::zookeeper::server
    include ::profile::zookeeper::firewall
}
