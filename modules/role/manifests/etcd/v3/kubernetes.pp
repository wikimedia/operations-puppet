# Role to configure an etcd v3 cluster for use in kubernetes.

class role::etcd::v3::kubernetes {
    include ::profile::standard
    include ::profile::base::firewall
    include ::profile::etcd::v3

    system::role { 'role::etcd::v3::kubernetes':
        description => 'kubernetes etcd cluster member'
    }
}
