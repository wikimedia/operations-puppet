# Simplified version of interface::ip, only used for adding secondary IPs to hosts
#
define interface::alias(
  $interface=$facts['interface_primary'],
  $ipv4=undef,
  $ipv6=undef,
) {
    if $ipv4 != undef or $ipv4 != false {
        interface::ip { "${title} ipv4":
            interface => $interface,
            address   => $ipv4,
            prefixlen => 32,
        }
    }

    if $ipv6 != undef or $ipv6 != false {
        interface::ip { "${title} ipv6":
            interface => $interface,
            address   => $ipv6,
            prefixlen => 128,
            # mark as deprecated = never pick this address unless explicitly asked
            options   => 'preferred_lft 0',
        }
    }
}
