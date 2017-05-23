# Definition: interface::rps
#
# Automagically sets RPS/RSS/XPS for an interface
#
# Parameters:
# - $interface:
#   The network interface to operate on
# - $rss_pattern:
#   Optional RSS IRQ name pattern (normally auto-detected)
define interface::rps($interface=$name, $rss_pattern='') {
    require interface::rpstools
    require interface::rps::modparams

    if $rss_pattern != '' {
        $cmd = "/usr/local/sbin/interface-rps ${interface} ${rss_pattern}"
    }
    else {
        $cmd = "/usr/local/sbin/interface-rps ${interface}"
    }

    # Disable irqbalance
    require irqbalance::disable

    # Add to ifup commands in /etc/network/interfaces
    interface::up_command { "rps-${interface}":
        interface => $interface,
        command   => $cmd,
    }

    # Exec immediately if newly-added
    exec { "rps-${interface}":
        command     => $cmd,
        subscribe   => Augeas["${interface}_rps-${interface}"],
        refreshonly => true,
    }
}

