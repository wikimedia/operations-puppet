class role::etcd {
    require standard
    include etcd


    ferm::rule{'etcd_clients':
        proto => 'tcp',
        port  => $etcd::client_port,
    }

    ferm::rule{'etcd_peers':
        proto => 'tcp',
        port  => $etcd::peer_port,
    }

    include etcd::monitoring

}
