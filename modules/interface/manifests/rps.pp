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

    # This sets the queue count at runtime if it's incorrect (first run or
    # change of numa_networking setting, before the module parameter from
    # ::modparams can take effect on next boot).  Changing at runtime *will*
    # blip the interface.  This shouldn't be an issue for first-run scenarios,
    # but might require a depool when changing $numa_networking on live
    # production hosts that can't handle short network blips.
    $num_queues = $::interface::rps::modparams::num_queues
    exec { "ethtool_rss_combined_channels_${interface}":
        path    => '/usr/bin:/usr/sbin:/bin:/sbin',
        command => "ethtool -L ${interface} combined ${num_queues}",
        unless  => "test $(ethtool -l ${interface} | tail -4 | awk '/Combined:/ { print \$2 }') = '${num_queues}'",
        require => Package['ethtool'],
        before  => Exec["rps-${interface}"],
    }
}
