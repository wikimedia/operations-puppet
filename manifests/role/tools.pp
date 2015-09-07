# Roles for Kubernetes and co on Tool Labs
class role::toollabs::etcd {
    include toollabs::infrastructure

    include role::etcd
}
