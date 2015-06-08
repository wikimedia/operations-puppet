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

    ferm::service{'etcd_clients':
        proto  => 'tcp',
        port   => $etcd::client_port,
        srange => '$ALL_NETWORKS',
    }

    ferm::service{'etcd_peers':
        proto  => 'tcp',
        port   => $etcd::peer_port,
        srange => '$ALL_NETWORKS',
    }

    include etcd
    include etcd::monitoring

}
