# Whitelist candidate kernel version for compute nodes

# 3.13 have a KSM bug and instance suspension causes complete system lockup
# see: https://bugs.launchpad.net/ubuntu/+source/linux/+bug/1346917
# 3.19 series kernels, instance clocks die after resuming from suspension
# Virtio has shown to be non-determinstic on certain host:client kernel
# version matchups (IO freezing)
class openstack::nova::compute::audit(
    $kernel_releases=['4.4.0-81-generic'],
    ) {

    if os_version('ubuntu >= trusty') {
        if ! ($::kernelrelease in $kernel_releases) {
            fail("nova-compute is only valid for ${kernel_releases} and not ${::kernelrelease}")
        }
    }

    # Starting with 3.18 (34666d467cbf1e2e3c7bb15a63eccfb582cdd71f) the netfilter code
    # was split from the bridge kernel module into a separate module (br_netfilter)
    if (versioncmp($::kernelversion, '3.18') >= 0) {
        kmod::module { 'br_netfilter':
            ensure => 'present',
        }
    }
}
