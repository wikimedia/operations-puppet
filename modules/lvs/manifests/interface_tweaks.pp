# This gathers up various ethernet settings for functional
#  fixups and optimizations specific to LVS in a single location
# Note this define contains an implicit assumption that eth0
#  is the primary interface and is treated differently wrt
#  forcing GRO off...

define lvs::interface_tweaks($bnx2x=false, $txqlen=false, $rss_pattern=false) {
    if ! os_version('debian >= jessie') {
        # Disable GRO (generically incompatible with LVS due to kernel issues, I believe this
        #   is now fixed upstream for both ipv4 and ipv6 as of kernel 3.7 or higher, but
        #   that idea needs testing!)
        interface::offload { "${name} gro": interface => $name, setting => 'gro', value => 'off' }
        if $name != 'eth0' {
            # Make sure GRO is off for the non-primary interfaces...
            interface::manual { $name: interface => $name, before => Interface::Offload["${name} gro"] }
        }

        # bnx2x is buggy with TPA (LRO) + LVS
        if $bnx2x {
            interface::offload { "${name} lro": interface => $name, setting => 'lro', value => 'off' }
        }
    }
    else {
        if $name != 'eth0' {
            interface::manual { $name: interface => $name }
        }
    }

    # RSS/RPS/XPS-type perf stuff ( https://www.kernel.org/doc/Documentation/networking/scaling.txt )
    if $rss_pattern { interface::rps { $name: rss_pattern => $rss_pattern } }

    # Optional larger TX queue len for 10Gbps+
    if $txqlen { interface::txqueuelen { $name: len => $txqlen } }

    # bnx2x-specific stuff
    if $bnx2x {
        # Max for bnx2x/BCM57800, seems to eliminate the spurious rx drops under heavy traffic
        interface::ring { "${name} rxring": interface => $name, setting => 'rx', value => 4078 }
    }
}
