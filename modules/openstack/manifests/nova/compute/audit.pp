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
}
