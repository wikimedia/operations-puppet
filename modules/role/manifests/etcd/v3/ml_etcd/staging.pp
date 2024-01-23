# Role to configure a *staging* etcd v3 cluster for use in ml_staging.

class role::etcd::v3::ml_etcd::staging {
    include profile::base::production
    include profile::firewall
    include profile::etcd::v3
}
