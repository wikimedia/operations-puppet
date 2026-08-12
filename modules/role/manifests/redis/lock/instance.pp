# SPDX-License-Identifier: Apache-2.0
class role::redis::lock::instance {
    include profile::base::production
    include profile::firewall

    # maxmemory depends on host's total memory
    $per_instance_memory = floor($facts['memory']['system']['total_bytes']  * 0.7)

    include profile::redis::master
}
