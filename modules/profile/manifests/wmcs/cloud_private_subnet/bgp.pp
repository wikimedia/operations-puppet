# SPDX-License-Identifier: Apache-2.0
class profile::wmcs::cloud_private_subnet::bgp (
    Hash[String, Wmflib::Advertise_vip] $vips = lookup('profile::bird::advertise_vips', { 'merge' => 'hash' }),
) {
    include profile::wmcs::cloud_private_subnet

    class { 'profile::bird::anycast':
        advertise_vips => $vips,  # we did a merge, the base profile does a simple lookup
        neighbors_list => [
            $profile::wmcs::cloud_private_subnet::gw_address_v4,
            $profile::wmcs::cloud_private_subnet::gw_address_v6,
        ].filter |$addr| { $addr != undef },
        ipv4_src       => $profile::wmcs::cloud_private_subnet::cloud_private_address_v4,
        ipv6_src       => $profile::wmcs::cloud_private_subnet::cloud_private_address_v6,
        multihop       => false,
    }

    $table = 'cloud-private'
    interface::routing_table { $table:
        number => 100,
    }

    interface::route { "${table}_default_gw4":
        interface => $profile::wmcs::cloud_private_subnet::interface,
        address   => 'default',
        nexthop   => $profile::wmcs::cloud_private_subnet::gw_address_v4,
        table     => $table,
        persist   => true,
    }

    if $profile::wmcs::cloud_private_subnet::gw_address_v6 != undef {
        interface::route { "${table}_default_gw6":
            interface => $profile::wmcs::cloud_private_subnet::interface,
            address   => 'default',
            nexthop   => $profile::wmcs::cloud_private_subnet::gw_address_v6,
            table     => $table,
            persist   => true,
        }
    }

    $vips.each |$entry_name, $vip_info| {
        interface::rule { "${table}_route_lookup_rule_${entry_name}_v4":
            interface => $profile::wmcs::cloud_private_subnet::interface,
            from      => $vip_info['address'],
            table     => $table,
        }

        if $profile::wmcs::cloud_private_subnet::gw_address_v6 != undef and $vip_info['address_ipv6'] {
            interface::rule { "${table}_route_lookup_rule_${entry_name}_v6":
                interface => $profile::wmcs::cloud_private_subnet::interface,
                from      => $vip_info['address_ipv6'],
                table     => $table,
            }
        }
    }
}
