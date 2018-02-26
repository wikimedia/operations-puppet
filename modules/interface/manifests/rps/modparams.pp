class interface::rps::modparams {
    include initramfs

    $iface = $facts['interface_primary']

    if $::numa_networking != 'off' {
        # note this assumes if bnx2x queue counts matter at all, that the
        # primary interface is bnx2x.  This is true for current cases, but may
        # need to evolve later for hosts with multiple interfaces with distinct
        # drivers, or the bonding case?
        # There's no avoiding the fact that this setting is global to the
        # driver, and therefore can't handle differing IRQ counts for different
        # bnx2x interfaces.  Again, not presently an issue...
        $num_queues = size($facts['numa']['device_to_htset'][$iface])
    }
    else {
        $num_queues = $facts['physicalcorecount']
    }

    # This sets it at boot time for future boots via driver param
    file { '/etc/modprobe.d/rps.conf':
        content => template("${module_name}/rps.conf.erb"),
        notify  => Exec['update-initramfs']
    }

    # This sets it at runtime if it's incorrect (first run or change of
    # numa_networking setting, before the above can take effect on next boot).
    # Changing at runtime *will* blip the interface.  This shouldn't be an
    # issue for first-run scenarios, but might require a depool when changing
    # $numa_networking on live production hosts.
    exec { "ethtool_rss_combined_channels":
        path    => '/usr/bin:/usr/sbin:/bin:/sbin',
        command => "ethtool -L ${iface} combined ${num_queues}",
        unless  => "test $(ethtool -l ${iface} | tail -4 | awk '/Combined:/ { print \$2 }') = '${num_queues}'",
        require => Package['ethtool'],
        before  => Exec["rps-${iface}"],
    }
}
