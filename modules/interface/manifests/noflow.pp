# Definition: interface::noflow
#
# Disable ethernet flow control at boot time via up-commands.
#
# Parameters:
# - $interface=$name:
#   The network interface to operate on
define interface::noflow($interface=$name) {
    # Command will fail on some hosts, depending on kernel/driver revs and/or
    # ethernet hardware capabilities, in which case we don't care, hence ||:
    $cmd = "ethtool -A ${interface} autoneg off tx off rx off ||:"

    # Add to ifup commands in /etc/network/interfaces
    interface::up_command { "noflow-${interface}":
        interface => $interface,
        command   => $cmd,
    }
}
