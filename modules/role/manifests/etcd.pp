# === Class role::etcd
#
# filtertags: labs-project-chasetest
class role::etcd {
    system::role { 'role::etcd':
        description => 'Highly-consistent distributed k/v store'
    }

    require standard
    include ::base::firewall

    include etcd
    include etcd::monitoring
    include etcd::auth::common

    ferm::service{'etcd_clients':
        proto  => 'tcp',
        port   => hiera('etcd::client_port', '2379'),
        srange => '$DOMAIN_NETWORKS',
    }

    ferm::service{'etcd_peers':
        proto  => 'tcp',
        port   => hiera('etcd::peer_port', '2380'),
        srange => '$DOMAIN_NETWORKS',
    }

    # Back up etcd
    require etcd::backup
    include role::backup::host
    backup::set { 'etcd': }
}
