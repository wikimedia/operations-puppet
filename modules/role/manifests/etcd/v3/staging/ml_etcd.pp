# Role to configure a *staging* etcd v3 cluster for use in ml_staging.

class role::etcd::v3::staging::ml_etcd {
    include ::profile::base::production
    include ::profile::base::firewall
    include ::profile::etcd::v3

    system::role { 'role::etcd::v3::staging::ml_etcd':
        description => 'ml_staging_etcd etcd cluster member'
    }
}
