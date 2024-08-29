# SPDX-License-Identifier: Apache-2.0
# This gathers up various ethernet settings for functional
#  fixups and optimizations specific to LVS in a single location

define profile::lvs::interface_tweaks(
  $interface=$name,
  $txqlen=false,
  $rss_pattern='',
  $do_rps=true,
  $ipip_enabled=false,
  $do_ipv6_ra_primary=false,
) {
    if $interface != $facts['interface_primary'] {
        interface::manual { $name:
            interface => $interface,
        }
    }

    if $do_ipv6_ra_primary {
      # Enable default route creation from IPv6 RA on primary interface: T358260
      if $interface == $facts['interface_primary'] {
          interface::pre_up_command { "${interface}-accept_ra_defrtr":
            interface => $interface,
            command   => "sysctl -w net.ipv6.conf.${interface}.accept_ra_defrtr=1",
          }
      }
    }

    # Disable LRO to avoid merging important headers for flow control and such
    interface::offload { "${interface}-lro":
        interface => $interface,
        setting   => 'lro',
        value     => 'off',
    }

    # RSS/RPS/XPS-type perf stuff ( https://www.kernel.org/doc/Documentation/networking/scaling.txt )
    if $do_rps {
        interface::rps { $name:
            interface   => $interface,
            rss_pattern => $rss_pattern,
        }
    }

    # Optional larger TX queue len for 10Gbps+
    if $txqlen {
        interface::txqueuelen { $name:
            interface => $interface,
            len       => $txqlen,
        }
    }

    # Max out ring buffers, seems to eliminate the spurious drops under heavy traffic
    $ring_size = $facts['net_driver'][$interface]['driver'] ? {
        'bnx2x' => 4078,
        'bnxt_en' => 2047,
    }

    if $facts['net_driver'][$interface]['driver'] =~ /^bnx(2x|t_en)$/ {
        interface::ring { "${name} rxring":
            interface => $interface,
            setting   => 'rx',
            value     => $ring_size,
        }

        # Disable ethernet PAUSE behavior, dropping is better than buffering (in reasonable cases!)
        interface::noflow { $interface: }
    }

    # bnxt_en also needs the tx set explicitly, unlike bnx2x above
    if $facts['net_driver'][$interface]['driver'] == 'bnxt_en' {
        interface::ring { "${name} txring":
            interface => $interface,
            setting   => 'tx',
            value     => $ring_size,
        }
    }

    # if we are using IPIP encapsulation we need the clsact qdisc + ipip-multiqueue-optimizer
    $ensure_clsact = bool2str($ipip_enabled, 'present', 'absent')
    interface::clsact { $name:
        ensure    => $ensure_clsact,
        interface => $interface,
    }
}
