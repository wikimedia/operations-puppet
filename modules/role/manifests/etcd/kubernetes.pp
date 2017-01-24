# Role class for the etcd cluster used by kubernetes.

class role::etcd::kubernetes {
    include ::standard
    include ::base::firewall
    include ::profile::etcd
    include ::profile::etcd::auth
}
