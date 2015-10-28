# Definition: interface::txqueuelen
#
# Sets interface txqueuelen
#
# Parameters:
# - $name:
#   The network interface to operate on
# - $len:
#   desired transmit queue length
define interface::txqueuelen($len) {
    $sysfs_txqlen = "/sys/class/net/${name}/tx_queue_len"
    $setcmd = "echo ${len} > ${sysfs_txqlen}"

    # Set in /etc/network/interfaces
    interface::up_command { "txqueuelen-${name}":
        interface => $name,
        command   => $setcmd,
    }

    # And make sure it's always active
    exec { "txqueuelen-${name}":
        path    => '/usr/bin:/usr/sbin:/bin:/sbin',
        command => $setcmd,
        unless  => "test `cat ${sysfs_txqlen}` = ${len}",
    }
}
