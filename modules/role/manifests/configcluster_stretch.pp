class role::configcluster_stretch {
    system::role { 'Configcluster':
        description => 'Configuration cluster server'
    }
    include ::profile::standard
    include ::profile::base::firewall

    # Temporary to ease the migration process; T271573
    if $::hostname !~ /conf200[456]/ {
        include ::profile::zookeeper::server
        include ::profile::zookeeper::firewall
    }

    include ::profile::etcd::v3
    include ::profile::etcd::tlsproxy
    include ::profile::etcd::replication
}
