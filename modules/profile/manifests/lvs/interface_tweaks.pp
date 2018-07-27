# This gathers up various ethernet settings for functional
#  fixups and optimizations specific to LVS in a single location

define profile::lvs::interface_tweaks(
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

    # Max out ring buffers, seems to eliminate the spurious drops under heavy traffic
    $ring_size = $facts['net_driver'][$interface]['driver'] ? {
        'bnx2x' => 4078,
        'bnxt_en' => 2047,
        'bnx2' => 2040,
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

    if $facts['net_driver'][$interface]['driver'] == 'bnxt_en' {
        interface::ring { "${name} txring":
            interface => $interface,
            setting   => 'tx',
            value     => $ring_size,
        }
    }
    elsif $facts['net_driver'][$interface]['driver'] == 'bnx2' {
        # lvs1001-6 have bnx2 1G cards, different maximum but still useful!
        # unlike bnx(2x|t_en), tx is different and we haven't historically tuned it
        interface::ring { "${name} rxring":
            interface => $interface,
            setting   => 'rx',
            value     => $ring_size,
        }

        # We don't use noflow here because PAUSE is doing useful things for this
        # case.  lvs1003 in particular can get overwhelmed in small bursts...
    }
}
