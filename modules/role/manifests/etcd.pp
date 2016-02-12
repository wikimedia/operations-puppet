# === Class role::etcd
class role::etcd {
    system::role { 'role::etcd':
        description => 'Highly-consistent distributed k/v store'
    }

    require standard
    include base::firewall

    include etcd
    include etcd::monitoring
    include etcd::auth::common

    ferm::service{'etcd_clients':
        proto  => 'tcp',
        port   => hiera('etcd::client_port', '2379'),
        srange => '$ALL_NETWORKS',
    }

    ferm::service{'etcd_peers':
        proto  => 'tcp',
        port   => hiera('etcd::peer_port', '2380'),
        srange => '$ALL_NETWORKS',
    }


}
