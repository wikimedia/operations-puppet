class role::redis::misc::master {
    include profile::base::production
    include profile::firewall

    # maxmemory depends on host's total memory
    $per_instance_memory = floor(($facts['memory']['system']['total_bytes'] / 1048576.0) * 0.8 / 5)

    include profile::redis::master
}
