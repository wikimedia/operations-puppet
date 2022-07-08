# SPDX-License-Identifier: Apache-2.0
# @summary Automagically sets RPS/RSS/XPS for an interface
#
# @param interface The network interface to operate on
# @param rss_pattern Optional RSS IRQ name pattern (normally auto-detected)
# @param qdisc Options qdisc string to populate mq subqueues, e.g.: "fq flow_limit 422"
# @param avoid_cpu0 If true, don't use CPU 0, to avoid contention issues (T236208)
define interface::rps(
  String           $interface   = $name,
  Optional[String] $rss_pattern = undef,
  Optional[String] $qdisc       = '',
  Boolean          $avoid_cpu0  = false,
) {
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

    # Note: tg3 (Broadcom Tigon3): driver defaults to 4 RX queues and 1 TX
    # queue, and supports raising the TX queues to 4 optionally as well, but
    # there's a comment in the tg3.c source code that says this is a bad idea,
    # as hardware may under-perform under some scenarios with multiple TX
    # queues (large packets starving access to tx queues full of smaller
    # packets).  Best left at defaults here!
}
