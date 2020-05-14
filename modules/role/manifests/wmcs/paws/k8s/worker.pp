class role::wmcs::paws::k8s::worker {
    system::role { $name: }

    include profile::wmcs::kubeadm::worker
}
