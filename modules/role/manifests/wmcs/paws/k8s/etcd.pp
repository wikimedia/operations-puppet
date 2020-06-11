class role::wmcs::paws::k8s::etcd {
    system::role { $name: }

    include ::profile::base::firewall
    include ::profile::wmcs::paws::common
    include ::profile::wmcs::kubeadm::etcd
}
