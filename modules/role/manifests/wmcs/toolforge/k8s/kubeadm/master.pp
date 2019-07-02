class role::wmcs::toolforge::k8s::kubeadm::master {
    system::role { $name: }

    include ::profile::toolforge::base
    include ::profile::toolforge::infrastructure
    include ::profile::toolforge::k8s::kubeadm::master
}
