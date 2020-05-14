class role::wmcs::paws::k8s::control {
    system::role { $name: }

    include ::profile::wmcs::kubeadm::control
}
