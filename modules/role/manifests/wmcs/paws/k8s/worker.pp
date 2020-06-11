class role::wmcs::paws::k8s::worker {
    system::role { $name: }

    include ::profile::wmcs::paws::common
    include profile::wmcs::kubeadm::worker
}
