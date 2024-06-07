# Role to configure an etcd v3 cluster for use in kubernetes.

class role::etcd::v3::kubernetes {
    include profile::base::production
    include profile::firewall
    include profile::etcd::v3
}
