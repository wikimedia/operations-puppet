class role::toollabs::etcd::flannel {
    include ::etcd

    # Send *all* the logs!
    include ::k8s::sendlogs

    include base::firewall

    $worker_hosts = join(hiera('k8s::worker_hosts'), ' ')
    $bastion_hosts = join(hiera('k8s::bastion_hosts'), ' ')
    $peer_hosts = join(hiera('flannel::etcd_hosts'), ' ')
    $proxy_hosts = join(hiera('toollabs::proxy::proxies'), ' ')
    $checker_hosts = join(hiera('toollabs::checker_hosts'), ' ')

    ferm::service { 'flannel-clients':
        proto  => 'tcp',
        port   => '2379',
        srange => "@resolve((${worker_hosts} ${peer_hosts} ${proxy_hosts} ${bastion_hosts} ${checker_hosts}))"
    }

    ferm::service { 'flannel-peers':
        proto  => 'tcp',
        port   => '2380',
        srange => "@resolve((${peer_hosts}))"
    }
}
