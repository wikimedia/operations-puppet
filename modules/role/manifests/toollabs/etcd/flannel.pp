class role::toollabs::etcd::flannel {
    include ::etcd

    include base::firewall

    $worker_nodes = join(hiera('k8s::worker_hosts'), ' ')
    $peer_nodes = join(hiera('flannel::etcd_hosts'), ' ')
    $proxy_nodes = join(hiera('toollabs::proxy::proxies'), ' ')

    ferm::service { 'flannel-clients':
        proto  => 'tcp',
        port   => '2379',
        srange => "@resolve((${worker_nodes} ${peer_nodes} ${proxy_nodes}))"
    }

    ferm::service { 'flannel-peers':
        proto  => 'tcp',
        port   => '2380',
        srange => "@resolve((${peer_nodes}))"
    }
}
