# This gathers up various ethernet settings for functional
#  fixups and optimizations specific to LVS in a single location

define lvs::interface_tweaks(
  $interface=$name,
  $bnx2x=false,
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
    if $bnx2x {
        # Max for bnx2x/BCM57800, seems to eliminate the spurious rx drops under heavy traffic
        interface::ring { "${name} rxring":
            interface => $interface,
            setting   => 'rx',
            value     => 4078,
        }
    }
    # lvs1001-6 have bnx2 1G cards, different maximum but still useful!
    else {
        interface::ring { "${name} rxring":
            interface => $interface,
            setting   => 'rx',
            value     => 2040,
        }
    }
}
