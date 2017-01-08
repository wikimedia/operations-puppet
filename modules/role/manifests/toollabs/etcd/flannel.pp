# filtertags: labs-project-tools
class role::toollabs::etcd::flannel {
    include ::etcd

    include base::firewall
    include ::role::toollabs::etcd::expose_metrics

    $worker_hosts = join(hiera('k8s::worker_hosts'), ' ')
    $bastion_hosts = join(hiera('k8s::bastion_hosts'), ' ')
    $peer_hosts = join(hiera('flannel::etcd_hosts'), ' ')
    $proxy_hosts = join(hiera('toollabs::proxy::proxies'), ' ')
    $checker_hosts = join(hiera('toollabs::checker_hosts'), ' ')

    ferm::service { 'flannel-clients':
        proto  => 'tcp',
        port   => '2379',
        srange => "@resolve((${worker_hosts} ${peer_hosts} ${proxy_hosts} ${bastion_hosts} ${checker_hosts}))",
    }

    ferm::service { 'flannel-peers':
        proto  => 'tcp',
        port   => '2380',
        srange => "@resolve((${peer_hosts}))",
    }
}
