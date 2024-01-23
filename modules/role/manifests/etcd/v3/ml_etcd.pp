# Role to configure an etcd v3 cluster for use in ml_etcd/ml_serve.

class role::etcd::v3::ml_etcd {
    include profile::base::production
    include profile::firewall
    include profile::etcd::v3
}
