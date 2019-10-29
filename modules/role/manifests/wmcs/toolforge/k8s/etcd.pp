class role::wmcs::toolforge::k8s::etcd {
    system::role { $name: }

    # this is for the old Debian Jessie VMs running the etcd cluster for the
    # old Toolforge kubernetes cluster. Once the old k8s is gone, this switch
    # can be removed
    if os_version('debian == jessie') {
        include role::toollabs::etcd::k8s
    }

    # this is for the new Debian Buster based etcd cluster for the new
    # Toolforge k8s deployment
    if os_version('debian == buster') {
        include ::profile::base::firewall
        include ::profile::toolforge::base
        include ::profile::toolforge::infrastructure
        include ::profile::toolforge::k8s::etcd
    }
}
