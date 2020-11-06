class role::wmcs::toolforge::k8s::etcd {
    system::role { $name: }

    # this is for the old Debian Jessie VMs running the etcd cluster for the
    # old Toolforge kubernetes cluster. Once the old k8s is gone, this switch
    # can be removed
    case debian::codename() {
        'jessie': {
            include role::toollabs::etcd::k8s
        }
        'buster': {
            include profile::base::firewall
            include profile::toolforge::base
            include profile::toolforge::infrastructure
            include profile::toolforge::k8s::etcd
            include profile::toolforge::prometheus_fixup
        }
        default: {
            fail("${debian::codename()}: not supported")
        }
    }
}
