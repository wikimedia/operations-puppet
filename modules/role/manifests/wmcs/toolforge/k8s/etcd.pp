class role::wmcs::toolforge::k8s::etcd {
    include profile::firewall
    include profile::toolforge::base
    include profile::toolforge::infrastructure
    include profile::toolforge::k8s::etcd
}
