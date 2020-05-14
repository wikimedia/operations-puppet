class role::wmcs::paws::k8s::haproxy {
    system::role { $name: }

    include profile::wmcs::kubeadm::haproxy
}
