# SPDX-License-Identifier: Apache-2.0
# Profile for Dumps distribution server in the Public VLAN,
# that serves dumps to Cloud VPS/Stat boxes via NFS,
# or via web or rsync to mirrors

class profile::dumps::distribution::monitoring {

    class { '::labstore::monitoring::interfaces':
        int_throughput_warn => 937500000,  # 7.5Gbps
        int_throughput_crit => 1062500000, # 8.5Gbps
    }
}
