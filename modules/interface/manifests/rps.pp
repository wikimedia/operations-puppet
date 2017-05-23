# Definition: interface::rps
#
# Automagically sets RPS/RSS/XPS for an interface
#
# Parameters:
# - $interface:
#   The network interface to operate on
# - $rss_pattern:
#   Optional RSS IRQ name pattern (normally auto-detected)
# - $qdisc
#   Options qdisc string to populate mq subqueues, e.g.:
#   "fq flow_limit 422"
define interface::rps($interface=$name, $rss_pattern='', $qdisc='') {
    require interface::rpstools
    require interface::rps::modparams

    $cmd = "/usr/local/sbin/interface-rps ${interface}"
    $cfg = "/etc/interface-rps.d/${interface}"

    file { $cfg:
        owner   => 'root',
        group   => 'root',
        mode    => '0555',
        content => template("${module_name}/interface-rps-config.erb"),
    }

    # Disable irqbalance
    require irqbalance::disable

    # Add to ifup commands in /etc/network/interfaces
    interface::up_command { "rps-${interface}":
        interface => $interface,
        command   => $cmd,
    }

    # Exec immediately on script or config change
    exec { "rps-${interface}":
        command     => $cmd,
        refreshonly => true,
        subscribe   => [
            File['/usr/local/sbin/interface-rps'],
            File[$cfg],
        ],
    }
}

