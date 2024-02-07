# SPDX-License-Identifier: Apache-2.0
class profile::wmcs::cloud_private_subnet (
    Stdlib::Fqdn                              $cloud_private_host = lookup('profile::wmcs::cloud_private_subnet::host'),
    String[1]                                 $cloud_private_gw_t = lookup('profile::wmcs::cloud_private_subnet::gw_template'),
    Integer[1,32]                             $netmask            = lookup('profile::wmcs::cloud_private_subnet::netmask', {'default_value' => 24}),
    Stdlib::IP::Address::V4::Cidr             $supernet           = lookup('profile::wmcs::cloud_private_subnet::supernet'),
    Array[Stdlib::IP::Address::V4::Cidr]      $public_cidrs       = lookup('profile::wmcs::cloud_private_subnet::public_cidrs'),
    String                                    $base_iface         = lookup('profile::wmcs::cloud_private_subnet::base_iface', {'default_value' => 'primary'}),
    Profile::Wmcs::Cloud_Private_Vlan_Mapping $vlan_mapping       = lookup('profile::wmcs::cloud_private_subnet::vlan_mapping'),
    Netbox::Device::Location                  $netbox_location    = lookup('profile::netbox::host::location'),
) {
    include network::constants

    $rack = downcase($netbox_location['rack'])
    $vlan_id = $vlan_mapping[$::site][$rack]

    $cloud_private_address = dnsquery::a($cloud_private_host) || { fail("failed to resolve '${cloud_private_host}'") }[0]

    if $base_iface == 'primary' {
        $iface = $facts['interface_primary']
    } else {
        $iface = $base_iface
    }

    interface::tagged { 'cloud_private_subnet_iface':
        base_interface     => $iface,
        vlan_id            => $vlan_id,
        method             => 'manual',
        up                 => 'ip link set $IFACE up',
        down               => 'ip link set $IFACE down',
        legacy_vlan_naming => false,
    }

    $interface = "vlan${vlan_id}"

    interface::ip { 'cloud_private_subnet_ip':
        interface => $interface,
        address   => $cloud_private_address,
        prefixlen => $netmask,
    }

    $cloud_private_gw = inline_epp($cloud_private_gw_t, { 'rack' => $rack })
    $gw_address = dnsquery::a($cloud_private_gw) || { fail("failed to resolve '${cloud_private_gw}'") }[0]

    interface::route { 'cloud_private_subnet_route_supernet':
        address   => split($supernet, '/')[0],
        prefixlen => Integer(split($supernet, '/')[1]),
        nexthop   => $gw_address,
        interface => $interface,
        persist   => true,
    }

    $public_cidrs.each  |$index, $cidr| {
        interface::route { "cloud_private_subnet_route_public_${index}":
            address   => split($cidr, '/')[0],
            prefixlen => Integer(split($cidr, '/')[1]),
            nexthop   => $gw_address,
            interface => $interface,
            persist   => true,
        }
    }

    $::network::constants::cloud_instance_networks[$netbox_location['site']].each |$cidr| {
        interface::route { "cloud_private_subnet_route_instances_${cidr}":
            address   => split($cidr, '/')[0],
            prefixlen => Integer(split($cidr, '/')[1]),
            nexthop   => $gw_address,
            interface => $interface,
            persist   => true,
        }
    }
}
