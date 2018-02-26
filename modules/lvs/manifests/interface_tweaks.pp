# This gathers up various ethernet settings for functional
#  fixups and optimizations specific to LVS in a single location

define lvs::interface_tweaks(
  $interface=$name,
  $txqlen=false,
  $rss_pattern='',
  $do_rps=true,
) {
    if $interface != $facts['interface_primary'] {
        interface::manual { $name:
            interface => $interface,
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

    # bnx2x-specific stuff
    if $facts['net_driver'][$interface] == 'bnx2x' {
        # Max for bnx2x/BCM57800, seems to eliminate the spurious rx drops under heavy traffic
        interface::ring { "${name} rxring":
            interface => $interface,
            setting   => 'rx',
            value     => 4078,
        }

        # Disable ethernet PAUSE behavior, dropping is better than buffering (in reasonable cases!)
        interface::noflow { $interface: }
    }
    else {
        # lvs1001-6 have bnx2 1G cards, different maximum but still useful!
        interface::ring { "${name} rxring":
            interface => $interface,
            setting   => 'rx',
            value     => 2040,
        }

        # We don't use noflow here because PAUSE is doing useful things for this
        # case.  lvs1003 in particular can get overwhelmed in small bursts...
    }
}
