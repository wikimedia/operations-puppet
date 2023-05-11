class role::wmcs::toolforge::k8s::etcd {
    system::role { $name: }

    include profile::firewall
    include profile::toolforge::base
    include profile::toolforge::infrastructure
    include profile::toolforge::k8s::etcd
}
