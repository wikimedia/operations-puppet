define interface::add_ip6_mapped($interface=undef, $ipv4_address=undef) {
    if ! $interface {
        $all_interfaces = split($::interfaces, ',')
        $intf = $all_interfaces[0]
    }
    else {
        $intf = $interface
    }

    if ! member(split($::interfaces, ','), $intf) {
        warning("Not adding IPv6 address to ${intf} because this interface does not exist!")
    }
    else {
        if ! $ipv4_address {
            $ip4_address = "::${::ipaddress}"
        }
        else {
            $ip4_address = "::${ipv4_address}"
        }

        # $v6_mapped_lower64 looks like '::10:0:2:1' for a v4 of '10.0.2.1'
        $v6_mapped_lower64 = regsubst($ip4_address, '\.', ':', 'G')

        $ipv6_address = inline_template("<%= require 'ipaddr'; require 'socket'; (IPAddr.new(scope.lookupvar(\"::ipaddress6_${intf}\"), Socket::AF_INET6).mask(64) | IPAddr.new(@v6_mapped_lower64, Socket::AF_INET6)).to_s() %>")
        interface::ip { $title:
            interface => $intf,
            address   => $ipv6_address,
            prefixlen => '64'
        }

        # The above sets up an "up" command to add the fixed IPv6 mapping of the v4
        # address statically, and also executes the command to add the address
        # in the present if not configured.
        #
        # Below sets "ip token" to the same on distros that support it.  The
        # token command explicitly configures the lower 64 bits that will be
        # used with any autoconf address, as opposed to one derived from the
        # macaddr.  This aligns the autoconf-assigned address with the fixed
        # one set above, and can do so as a pre-up command to avoid ever
        # having another address even temporarily, when this is all set up
        # before boot.
        # We can't rely on the token part exclusively, though, or we'd face
        # race conditions: daemons would expect to be able to bind this
        # address for listening immediately after network-up, but the address
        # wouldn't exist until the next RA arrives on the interface, which can
        # be 1-2s in practice.
        # By keeping both the static config from above and the token command,
        # we get the best of all worlds: no race, and no conflicting
        # macaddr-based assignment on the interface either.  When this is
        # first applied at runtime it will execute the token command as well,
        # but any previous macaddr-based address will be flushed.

        if os_version('debian >= jessie || ubuntu >= trusty') {
            $v6_token_cmd = "/sbin/ip token set ${v6_mapped_lower64} dev ${intf}"
            $v6_flush_dyn_cmd = "/sbin/ip -6 addr flush dev ${intf} dynamic"
            $v6_token_check_cmd = "/sbin/ip token get dev ${intf} | grep -qw ${v6_mapped_lower64}"
            $v6_token_preup_cmd = "set iface[. = '${intf}']/pre-up '${v6_token_cmd}'"

            augeas { "${intf}_v6_token":
                context => '/files/etc/network/interfaces/',
                changes => $v6_token_preup_cmd,
            }

            exec { "${intf}_v6_token":
                command => "${v6_token_cmd} && ${v6_flush_dyn_cmd}",
                unless  => $v6_token_check_cmd,
            }
        }
    }
}
