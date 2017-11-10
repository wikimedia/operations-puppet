# Role class for the etcd cluster used by kubernetes.

class role::etcd::kubernetes {
    include ::standard
    include ::base::firewall
    include ::profile::etcd
    include ::profile::etcd::auth

    system::role { 'role::etcd::kubernetes':
        description => 'kubernetes etcd cluster member'
    }
}
