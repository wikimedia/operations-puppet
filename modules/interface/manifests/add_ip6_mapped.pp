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

        $ipv6_address = inline_template("<%= require 'ipaddr'; (IPAddr.new(scope.lookupvar(\"::ipaddress6_${intf}\")).mask(64) | IPAddr.new(v6_mapped_lower64)).to_s() %>")
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
        # having another address even temporarily.  We could probably rely on
        # this exclusively and drop the static address above, but the
        # redundancy doesn't hurt (the autoconf simply won't end up appearing
        # on the list at all when it duplicates the static address), and this
        # allays any fears about relying on router advertisments.  As above,
        # this also executes itself in the present when first configured.

        if os_version('debian >= jessie || ubuntu >= trusty') {
            $v6_token_cmd = "/sbin/ip token set $v6_mapped_lower64 dev ${intf}"
            $v6_token_check_cmd = "/sbin/ip token get dev $intf | grep -qw $v6_mapped_lower64"
            $v6_token_preup_cmd = "set iface[. = '${intf}']/pre-up '${v6_token_cmd}'"

            augeas { "${intf}_v6_token":
                context => '/files/etc/network/interfaces/',
                changes => $v6_token_preup_cmd,
            }

            exec { "${intf}_v6_token":
                command => $v6_token_cmd,
                unless  => $v6_token_check_cmd,
            }
        }
    }
}
