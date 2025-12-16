# SPDX-License-Identifier: Apache-2.0
# Simplified version of interface::ip, only used for adding secondary IPs to hosts
#
define interface::alias(
  String $interface=$facts['interface_primary'],
  Optional[Stdlib::IP::Address::V4::Nosubnet] $ipv4=undef,
  Optional[Stdlib::IP::Address::V6::Nosubnet] $ipv6=undef,
  Boolean $is_service_ip=true,
) {
    if $ipv4 != undef {
        $prefixlen_v4 = $is_service_ip ? {
            true  => 32,
            false => wmflib::mask2cidr($facts['networking']['interfaces'][$interface]['netmask']),
        }
        interface::ip { "${title} ipv4":
            interface => $interface,
            address   => $ipv4,
            prefixlen => $prefixlen_v4,
        }
    }

    if $ipv6 != undef {
        $prefixlen_v6 = $is_service_ip ? {
            true  => 128,
            false => wmflib::mask2cidr($facts['networking']['interfaces'][$interface]['netmask6']),
        }
        interface::ip { "${title} ipv6":
            interface => $interface,
            address   => $ipv6,
            prefixlen => $prefixlen_v6,
            # mark as deprecated = never pick this address unless explicitly asked
            options   => 'preferred_lft 0',
        }
    }
}
