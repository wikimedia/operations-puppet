class interface::rps::modparams {
    include initramfs

    if $::numa_networking {
        # note this assumes if bnx2x queue counts matter at all, that the
        # primary interface is bnx2x.  This is true for current cases, but may
        # need to evolve later for hosts with multiple interfaces with distinct
        # drivers, or the bonding case?
        # There's no avoiding the fact that this setting is global to the
        # driver, and therefore can't handle differing IRQ counts for different
        # bnx2x interfaces.  Again, not presently an issue...
        $num_queues = size($facts['numa']['device_to_htset'][$facts['interface_primary']])
    }
    else {
        $num_queues = $facts['physicalcorecount']
    }

    file { '/etc/modprobe.d/rps.conf':
        content => template("${module_name}/rps.conf.erb"),
        notify  => Exec['update-initramfs']
    }
}
