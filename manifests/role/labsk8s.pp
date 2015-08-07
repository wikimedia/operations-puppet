class role::labs::k8s::master {
    $master_host = hiera('k8s_master', $::fqdn)
    $etcd_servers = hiera('etcd_servers')

    class { 'k8s::kubelet':
        master_host => $master_host,
    }

    class { 'k8s::apiserver':
        master_host => $master_host,
        etcd_servers => $etcd_servers,

    }

    class { 'k8s::scheduler':
        master_host => $master_host,
    }

    include role::labs::k8s::worker
}

class role::labs::k8s::worker {
    include k8s::docker
}
