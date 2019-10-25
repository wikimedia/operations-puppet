class role::wmcs::ceph::mon {
    system::role { $name: }
    include ::profile::standard
    include ::profile::base::firewall
    include ::profile::ceph::etcd
    include ::profile::ceph::k8s::control
    include ::profile::ceph::k8s::node
}
