# Roles for Kubernetes and co on Tool Labs
class role::toollabs::etcd {
    # To deny access to etcd - atm the kubernetes master
    # and etcd will be on the same host, so ok to just deny
    # access to everyone else
    include base::firewall
    include toollabs::infrastructure

    include etcd
}
