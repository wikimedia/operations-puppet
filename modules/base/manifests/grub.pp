class base::grub(
  $ioscheduler = 'deadline',
  $enable_memory_cgroup = false,
  $tcpmhash_entries = 0
) {
    include ::grub::defaults

    if versioncmp($::augeasversion, '1.2.0') >= 0 {
        ::grub::bootparam { 'elevator':
            ensure => present,
            value  => 'deadline',
        }

        $cgroup_ensure = $enable_memory_cgroup ? {
            true  => 'present',
            false => 'absent',
        }

        ::grub::bootparam { 'cgroup_enable':
            ensure => $cgroup_ensure,
            value  => 'memory',
        }

        ::grub::bootparam { 'swapaccount':
            ensure => $cgroup_ensure,
            value  => '1',
        }

        $tcpmhash_ensure = $tcpmhash_entries ? {
            0       => 'absent',
            default => 'present',
        }

        ::grub::bootparam { 'tcpmhash_entries':
            ensure => $tcpmhash_ensure,
            value  => $tcpmhash_entries,
        }
    }
}
