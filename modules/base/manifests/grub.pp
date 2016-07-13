class base::grub(
  $enable_memory_cgroup = false,
) {
    include ::grub::defaults

    if versioncmp($::augeasversion, '1.2.0') >= 0 {
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
    }
}
