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

    exec { 'ksm_sleep':
        path    => '/bin',
        command => 'echo 100 > /sys/kernel/mm/ksm/sleep_millisecs',
        unless  => 'grep -q 100 /sys/kernel/mm/ksm/sleep_millisecs',
    }
    exec { 'ksm_run':
        path    => '/bin',
        command => 'echo 1 > /sys/kernel/mm/ksm/run',
        unless  => 'grep -q 1 /sys/kernel/mm/ksm/run',
    }
}
