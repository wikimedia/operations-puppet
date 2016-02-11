class role::toollabs::etcd::k8s {
    include ::etcd
    include base::firewall

    $peer_nodes = join(hiera('k8s::etcd_hosts'), ' ')
    $k8s_master = hiera('k8s::master_host')

    ferm::service { 'etcd-clients':
        proto  => 'tcp',
        port   => '2379',
        srange => "@resolve((${k8s_master} ${peer_nodes}))"
    }

    ferm::service { 'etcd-peers':
        proto  => 'tcp',
        port   => '2380',
        srange => "@resolve((${peer_nodes}))"
    }
}
