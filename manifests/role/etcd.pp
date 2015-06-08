# === Class role::etcd
#
# Virtual resource for the monitoring server
@monitoring::group { 'etcd_eqiad':
    description => 'eqiad Etcd',
}

class role::etcd {
    system::role { 'role::etcd':
        description => 'Highly-consistent distributed k/v store'
    }

    require standard
    include base::firewall

    include etcd
    include etcd::monitoring


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
