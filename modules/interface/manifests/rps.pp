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
# - $avoid_cpu0:
#   If true, don't use CPU 0, to avoid contention issues (T236208)
define interface::rps($interface=$name, $rss_pattern='', $qdisc='', $avoid_cpu0='') {
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

    # This sets the queue count at runtime if it's incorrect (first run
    # or after a reboot).  Changing at runtime *will* blip the interface.  This
    # shouldn't be an issue for first-run scenarios, but might require a depool
    # on live production hosts that can't handle short network blips.
    if $facts['net_driver'][$interface]['driver'] =~ /^bnx(2x|t_en)/ {
        # Limit to known cases bnx2x and bnxt_en which generally allow tons of
        # queues, so that we can generally configure them for all non-HT cores
        # on the interface's NUMA node.
        $num_queues = size($facts['numa']['device_to_htset'][$interface])
        exec { "ethtool_rss_combined_channels_${interface}":
            path    => '/usr/bin:/usr/sbin:/bin:/sbin',
            command => "ethtool -L ${interface} combined ${num_queues}",
            unless  => "test $(ethtool -l ${interface} | tail -4 | awk '/Combined:/ { print \$2 }') = '${num_queues}'",
            require => Package['ethtool'],
            before  => Exec["rps-${interface}"],
        }
    }
    # Note: tg3 (Broadcom Tigon3): driver defaults to 4 RX queues and 1 TX
    # queue, and supports raising the TX queues to 4 optionally as well, but
    # there's a comment in the tg3.c source code that says this is a bad idea,
    # as hardware may under-perform under some scenarios with multiple TX
    # queues (large packets starving access to tx queues full of smaller
    # packets).  Best left at defaults here!
}
