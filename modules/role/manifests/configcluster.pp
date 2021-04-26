class role::configcluster {
    include ::profile::standard
    include ::profile::base::firewall

    include ::profile::etcd
    include ::profile::etcd::tlsproxy
    include ::profile::etcd::replication

    system::role { 'configcluster':
        description => 'Configuration cluster server'
    }
}
