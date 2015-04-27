# Class ganeti::kvm
#
# Install KVM and setup Kernel Same-page Merging to save memory via memory
# deduplication
#
# Parameters:
#
# Actions:
#   Install KVM and configure Kernel Same-page Merging
#
# Requires:
#
# Sample Usage
#   include ganeti::kvm
class ganeti::kvm {
    package { 'qemu-system-x86':
        ensure => present,
    }

    sysfs::parameters { 'ksm':
        values => {
            'kernel.mm.ksm.run'             => '1',
            'kernel.mm.ksm.sleep_millisecs' => '100',
        },
    }
}
