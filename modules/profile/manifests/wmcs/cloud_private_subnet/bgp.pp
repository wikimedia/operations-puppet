# SPDX-License-Identifier: Apache-2.0
class profile::wmcs::cloud_private_subnet::bgp (
    Stdlib::Fqdn                              $cloud_private_host = lookup('profile::wmcs::cloud_private_subnet::host'),
    String[1]                                 $cloud_private_gw_t = lookup('profile::wmcs::cloud_private_subnet::gw_template'),
    Profile::Wmcs::Cloud_Private_Vlan_Mapping $vlan_mapping       = lookup('profile::wmcs::cloud_private_subnet::vlan_mapping'),
    Hash[String, Wmflib::Advertise_vip]       $vips               = lookup('profile::bird::advertise_vips', { 'merge' => 'hash' }),
    Netbox::Device::Location                  $netbox_location    = lookup('profile::netbox::host::location'),
) {
    $cloud_private_address = dnsquery::a($cloud_private_host) || { fail("failed to resolve '${cloud_private_host}'") }[0]
    $rack = downcase($netbox_location['rack'])
    $cloud_private_gw = inline_epp($cloud_private_gw_t, { 'rack' => $rack })
    $gw_address = dnsquery::a($cloud_private_gw) || { fail("failed to resolve '${cloud_private_gw}'") }[0]

    $vlan_id = $vlan_mapping[$::site][$rack]
    $interface = "vlan${vlan_id}"

    class { 'profile::bird::anycast':
        advertise_vips => $vips,  # we did a merge, the base profile does a simple lookup
        neighbors_list => [$gw_address],
        ipv4_src       => $cloud_private_address,
        multihop       => false,
    }

    $table = 'cloud-private'
    interface::routing_table { $table:
        number => 100,
    }

    interface::route { "${table}_default_gw":
        interface => $interface,
        address   => 'default',
        nexthop   => $gw_address,
        table     => $table,
        persist   => true,
    }

    interface::post_up_command { "${table}_default_gw":
        ensure    => absent,
        interface => $interface,
        command   => "ip route add default via ${gw_address} table ${table}",
    }

    $vips.each |$entry_name, $vip_info| {
        interface::rule { "${table}_route_lookup_rule_${entry_name}":
            interface => $interface,
            from      => $vip_info['address'],
            table     => $table,
        }
    }
}
