# filtertags: labs-project-tools
class role::toollabs::etcd::k8s {
    include ::etcd
    include ::base::firewall

    include ::role::toollabs::etcd::expose_metrics

    $peer_nodes = join(hiera('k8s::etcd_hosts'), ' ')
    $checker_hosts = join(hiera('toollabs::checker_hosts'), ' ')
    $master_hosts = join(hiera('k8s::master_hosts'), ' ')

    ferm::service { 'etcd-clients':
        proto  => 'tcp',
        port   => '2379',
        srange => "@resolve((${master_hosts} ${peer_nodes} ${checker_hosts}))",
    }

    ferm::service { 'etcd-peers':
        proto  => 'tcp',
        port   => '2380',
        srange => "@resolve((${peer_nodes}))",
    }
}
