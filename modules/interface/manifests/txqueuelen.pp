# Definition: interface::txqueuelen
#
# Sets interface txqueuelen
#
# Parameters:
# - $interface:
#   The network interface to operate on
# - $len:
#   desired transmit queue length
define interface::txqueuelen($interface=$name, $len) {
    $sysfs_txqlen = "/sys/class/net/${interface}/tx_queue_len"
    $setcmd = "echo ${len} > ${sysfs_txqlen}"

    # Set in /etc/network/interfaces
    interface::up_command { "txqueuelen-${interface}":
        interface => $interface,
        command   => $setcmd,
    }

    # And make sure it's always active
    exec { "txqueuelen-${interface}":
        path    => '/usr/bin:/usr/sbin:/bin:/sbin',
        command => $setcmd,
        unless  => "test `cat ${sysfs_txqlen}` = ${len}",
    }
}
