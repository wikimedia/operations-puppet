class role::configcluster_stretch {
    system::role { 'Configcluster':
        description => 'Configuration cluster server (stretch)'
    }
    include ::standard
    include ::profile::base::firewall

    # Temporary to ease the migration process
    if $::hostname =~ /conf1004/ {
        include ::profile::zookeeper::server
        include ::profile::zookeeper::firewall
    }
    include ::profile::etcd::v3
    include ::profile::etcd::tlsproxy
    # Replication is not active during the setup phase.
    #include ::profile::etcd::replication
}
