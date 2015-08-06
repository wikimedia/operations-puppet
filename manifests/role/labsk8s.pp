class role::labs::k8s::master {
    class { 'k8s::kubelet':
        master_host => hiera('k8s_master', $::fqdn),
    }

    include role::labs::k8s::worker
}

class role::labs::k8s::worker {
    include k8s::flannel
}
