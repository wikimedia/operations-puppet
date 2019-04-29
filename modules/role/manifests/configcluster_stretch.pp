class role::configcluster_stretch {
    system::role { 'Configcluster':
        description => 'Configuration cluster server (stretch)'
    }
    include ::profile::standard
    include ::profile::base::firewall

    include ::profile::zookeeper::server
    include ::profile::zookeeper::firewall

    include ::profile::etcd::v3
    include ::profile::etcd::tlsproxy
    include ::profile::etcd::replication
}
