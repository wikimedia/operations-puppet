# Definition: interface::rps
#
# Automagically sets RPS (and optionally, RSS) for an interface
#
# Parameters:
# - $interface:
#   The network interface to operate on
# - $rss_pattern:
#   Optional RSS IRQ name pattern
#   If set (to hw-specific value), RSS will be enabled as well
#   Must contain a single "%d" format character for the queue number
#   (on bnx2x, this would be "eth0-fp-%d")
define interface::rps( $rss_pattern='' ) {
    require interface::rpstools
    require interface::rps::modparams

    $interface = $title
    if $rss_pattern != '' {
        $cmd = "/usr/local/sbin/interface-rps ${interface} ${rss_pattern}"
    }
    else {
        $cmd = "/usr/local/sbin/interface-rps ${interface}"
    }

    # Disable irqbalance if RSS in use
    if $rss_pattern != '' {
        require irqbalance::disable
    }

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

