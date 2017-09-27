# Definition: interface::noflow
#
# Disable ethernet flow control at boot time via up-commands, and also at
# runtime when first adding to boot time up-commands, so that it's applied on
# freshly-installed hosts without another reboot required.
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

    # Exec immediately at runtime when first added to interfaces file
    exec { "noflow-${interface}":
        path        => '/usr/bin:/usr/sbin:/bin:/sbin',
        command     => $cmd,
        require     => Package['ethtool'],
        subscribe   => Augeas["${interface}_noflow-${interface}"],
        refreshonly => true,
    }
}
