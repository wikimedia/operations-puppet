# SPDX-License-Identifier: Apache-2.0
# @summary This class enables memory cgroups on debian, where they're
#  disabled by default.
class profile::base::memory_cgroup {
    # Enable memory cgroup
    grub::bootparam { 'cgroup_enable':
        value => 'memory',
    }

    grub::bootparam { 'swapaccount':
        value => '1',
    }
}
