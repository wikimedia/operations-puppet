class role::toollabs::etcd::k8s {
    include ::etcd
    include base::firewall

    # Send *all* the logs!
    include ::k8s::sendlogs

    $peer_nodes = join(hiera('k8s::etcd_hosts'), ' ')
    $checker_hosts = join(hiera('toollabs::checker_hosts'), ' ')
    $k8s_master = hiera('k8s::master_host')

    ferm::service { 'etcd-clients':
        proto  => 'tcp',
        port   => '2379',
        srange => "@resolve((${k8s_master} ${peer_nodes} ${checker_hosts}))"
    }

    ferm::service { 'etcd-peers':
        proto  => 'tcp',
        port   => '2380',
        srange => "@resolve((${peer_nodes}))"
    }
}
