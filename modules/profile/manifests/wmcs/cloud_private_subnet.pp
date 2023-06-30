# SPDX-License-Identifier: Apache-2.0
class profile::wmcs::cloud_private_subnet (
    Stdlib::Fqdn                         $cloud_private_host = lookup('profile::wmcs::cloud_private_subnet::host'),
    Stdlib::Fqdn                         $cloud_private_gw   = lookup('profile::wmcs::cloud_private_subnet::gw'),
    Integer[1,32]                        $netmask            = lookup('profile::wmcs::cloud_private_subnet::netmask', {'default_value' => 24}),
    Integer[0,4094]                      $vlan_id            = lookup('profile::wmcs::cloud_private_subnet::vlan_id'),
    Stdlib::IP::Address::V4::Cidr        $supernet           = lookup('profile::wmcs::cloud_private_subnet::supernet'),
    Array[Stdlib::IP::Address::V4::Cidr] $public_cidrs       = lookup('profile::wmcs::cloud_private_subnet::public_cidrs'),
    String                               $base_iface         = lookup('profile::wmcs::cloud_private_subnet::base_iface', {'default_value' => 'primary'}),
) {
    $cloud_private_address = dnsquery::a($cloud_private_host)[0]

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

    $gw_address = dnsquery::a($cloud_private_gw)[0]

    interface::route { 'cloud_private_subnet_route_supernet':
        address   => split($supernet, '/')[0],
        prefixlen => split($supernet, '/')[1],
        nexthop   => $gw_address,
        interface => $interface,
        persist   => true,
    }

    $public_cidrs.each  |$index, $cidr| {
        interface::route { "cloud_private_subnet_route_public_${index}":
            address   => split($cidr, '/')[0],
            prefixlen => split($cidr, '/')[1],
            nexthop   => $gw_address,
            interface => $interface,
            persist   => true,
        }
    }
}
