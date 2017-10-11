class role::configcluster {
    include ::standard
    include ::profile::base::firewall
    include ::profile::zookeeper::server
    include ::profile::zookeeper::firewall
    include ::profile::etcd
    include ::profile::etcd::tlsproxy
    include ::profile::etcd::replication
}
