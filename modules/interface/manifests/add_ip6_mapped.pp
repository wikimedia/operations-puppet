# Sets up a static IPv6 address on the host, based on its IPv4 address
#
# Example: for a host with an IPv4 address of 208.80.154.149, this will
# statically configure it to have an address of 2620:0:861:2:208:80:154:149.
#
# This relies on IPv6 SLAAC to be working and uses it to find the IPv6 network
# (the first 64-bits of the IPv6 address. This also doesn't touch the routing
# table and thus relies on SLAAC for configuring the default route.

define interface::add_ip6_mapped(
  $interface=$::interface_primary,
  $ipv4_address=$::ipaddress_primary,
) {
    if ! member(split($::interfaces, ','), $interface) {
        fail("Not adding IPv6 address to ${interface} because this interface does not exist!")
    }

    # $v6_mapped_lower64 looks like '::10:0:2:1' for a v4 of '10.0.2.1'
    $ipv4_address_with_colons = regsubst($ipv4_address, '\.', ':', 'G')
    $v6_mapped_lower64 = "::${ipv4_address_with_colons}"

    $ipv6_address = inline_template("<%= require 'ipaddr'; (IPAddr.new(scope.lookupvar(\"::ipaddress6_${interface}\")).mask(64) | IPAddr.new(@v6_mapped_lower64)).to_s() %>")
    interface::ip { $title:
        interface => $interface,
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

    $v6_token_cmd = "/sbin/ip token set ${v6_mapped_lower64} dev ${interface}"
    $v6_flush_dyn_cmd = "/sbin/ip -6 addr flush dev ${interface} dynamic"
    $v6_token_check_cmd = "/sbin/ip token get dev ${interface} | grep -qw ${v6_mapped_lower64}"
    $v6_token_preup_cmd = "set iface[. = '${interface}']/pre-up '${v6_token_cmd}'"

    augeas { "${interface}_v6_token":
        context => '/files/etc/network/interfaces/',
        changes => $v6_token_preup_cmd,
    }

    exec { "${interface}_v6_token":
        command => "${v6_token_cmd} && ${v6_flush_dyn_cmd}",
        unless  => $v6_token_check_cmd,
    }
}
