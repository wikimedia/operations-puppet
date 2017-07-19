class role::configcluster {
    include ::standard
    include ::base::firewall
    include ::profile::zookeeper::server
    include ::profile::zookeeper::firewall::main
    include ::profile::etcd
    include ::profile::etcd::tlsproxy
    include ::profile::etcd::replication
}
