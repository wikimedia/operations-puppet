class role::configcluster {
    include ::standard
    include ::base::firewall

    # Temporary to ease the migration process
    if $::hostname !~ /conf100[12]/ {
        include ::profile::zookeeper::server
        include ::profile::zookeeper::firewall
    }
    include ::profile::etcd
    include ::profile::etcd::tlsproxy
    include ::profile::etcd::replication
}
