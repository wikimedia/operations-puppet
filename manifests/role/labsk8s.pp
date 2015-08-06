class role::labs::k8s::master {
    class { 'k8s::kubelet':
        master_host => hiera('k8s_master', $::fqdn),
    }
}
