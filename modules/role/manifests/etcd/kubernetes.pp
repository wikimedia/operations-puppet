# Role class for the etcd cluster used by kubernetes.
# Should only include other roles.

class role::etcd::kubernetes {
    include standard
    include base::firewall
    include role::etcd::common
}
