# === Class role::etcd
#
class role::etcd {
    system::role { 'role::etcd':
        description => 'Highly-consistent distributed k/v store'
    }

    require standard
    include base::firewall

    ferm::rule{'etcd_clients':
        proto => 'tcp',
        port  => $etcd::client_port,
    }

    ferm::rule{'etcd_peers':
        proto => 'tcp',
        port  => $etcd::peer_port,
    }

    include etcd
    include etcd::monitoring

}
