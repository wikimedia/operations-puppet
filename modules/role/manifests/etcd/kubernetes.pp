# Role class for the etcd cluster used by kubernetes.

class role::etcd::kubernetes {
    include ::profile::standard
    include ::profile::base::firewall
    include ::profile::etcd

    system::role { 'role::etcd::kubernetes':
        description => 'kubernetes etcd cluster member'
    }
}
