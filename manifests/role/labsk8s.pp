class role::labs::k8s::master {
    class { 'k8s::kubelet':
        master_host => hiera('k8s_master', $::fqdn),
    }

    $etcd_servers = hiera('etcd_servers')

    class { 'k8s::apiserver':
        etcd_servers => $etcd_servers,
    }

    include role::labs::k8s::worker
}

class role::labs::k8s::worker {
    include k8s::docker
}
