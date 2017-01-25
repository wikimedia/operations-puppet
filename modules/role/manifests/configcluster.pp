class role::configcluster {
    include ::standard
    include ::base::firewall
    include ::role::zookeeper::server
    include ::profile::etcd
    include ::profile::etcd::tlsproxy
}
