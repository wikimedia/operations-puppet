# Role class for the etcd cluster used by kubernetes staging.

class role::kubernetes::staging::etcd {
    include ::profile::standard
    include ::profile::base::firewall
    include ::profile::etcd
    include ::profile::etcd::auth
}
