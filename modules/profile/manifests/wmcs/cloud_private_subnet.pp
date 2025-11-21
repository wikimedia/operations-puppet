# SPDX-License-Identifier: Apache-2.0
class profile::wmcs::cloud_private_subnet (
    Stdlib::Fqdn                     $cloud_private_host = lookup('profile::wmcs::cloud_private_subnet::host'),
    String[1]                        $cloud_private_gw_t = lookup('profile::wmcs::cloud_private_subnet::gw_template'),
    Integer[1,32]                    $netmask_v4         = lookup('profile::wmcs::cloud_private_subnet::netmask_v4', {'default_value' => 24}),
    Integer[1,128]                   $netmask_v6         = lookup('profile::wmcs::cloud_private_subnet::netmask_v6', {'default_value' => 64}),
    Stdlib::IP::Address::V4::Cidr    $supernet_v4        = lookup('profile::wmcs::cloud_private_subnet::supernet_v4'),
    Stdlib::IP::Address::V6::Cidr    $supernet_v6        = lookup('profile::wmcs::cloud_private_subnet::supernet_v6'),
    Array[Wmflib::IP::Address::CIDR] $public_cidrs       = lookup('profile::wmcs::cloud_private_subnet::public_cidrs'),
    Optional[String[1]]              $base_iface         = lookup('profile::wmcs::cloud_private_subnet::base_iface', {default_value => undef}),
    Profile::Wmcs::Vlan_Mapping      $vlan_mapping       = lookup('profile::wmcs::cloud_private_subnet::vlan_mapping'),
    Netbox::Device::Location         $netbox_location    = lookup('profile::netbox::host::location'),
) {
    include network::constants

    $rack = downcase($netbox_location['rack'])
    $vlan_id = $vlan_mapping[$::site][$rack]

    $cloud_private_address_v4 = dnsquery::a($cloud_private_host)[0]
    $cloud_private_address_v6 = dnsquery::aaaa($cloud_private_host)[0]

    $base_interface = $base_iface.lest || { $facts['interface_primary'] }

    interface::tagged { 'cloud_private_subnet_iface':
        base_interface => $base_interface,
        vlan_id        => $vlan_id,
        method         => 'manual',
        up             => 'ip link set $IFACE up',
        down           => 'ip link set $IFACE down',
    }

    $interface = "vlan${vlan_id}"

    interface::ip { 'cloud_private_subnet_ip4':
        interface => $interface,
        address   => $cloud_private_address_v4,
        prefixlen => $netmask_v4,
    }

    interface::ip { 'cloud_private_subnet_ip6':
        interface => $interface,
        address   => $cloud_private_address_v6,
        prefixlen => $netmask_v6,
    }

    interface::mtu { [ $base_interface, $interface ]:
        mtu => 9000,
    }

    $cloud_private_gw = inline_epp($cloud_private_gw_t, { 'rack' => $rack })
    $gw_address_v4 = dnsquery::a($cloud_private_gw)[0]
    $gw_address_v6 = dnsquery::aaaa($cloud_private_gw)[0]

    interface::route { 'cloud_private_subnet_route_supernet4':
        address   => $supernet_v4,
        nexthop   => $gw_address_v4,
        interface => $interface,
        persist   => true,
    }

    interface::route { 'cloud_private_subnet_route_supernet6':
        address   => $supernet_v6,
        nexthop   => $gw_address_v6,
        interface => $interface,
        persist   => true,
    }

    $public_cidrs.each |$cidr| {
        $gw = wmflib::ip_family($cidr) ? {
            4 => $gw_address_v4,
            6 => $gw_address_v6,
        }

        interface::route { "cloud_private_subnet_route_public_${cidr}":
            address   => $cidr,
            nexthop   => $gw,
            interface => $interface,
            persist   => true,
        }
    }

    $::network::constants::cloud_instance_networks[$netbox_location['site']].each |$cidr| {
        $gw = wmflib::ip_family($cidr) ? {
            4 => $gw_address_v4,
            6 => $gw_address_v6,
        }

        interface::route { "cloud_private_subnet_route_instances_${cidr}":
            address   => $cidr,
            nexthop   => $gw,
            interface => $interface,
            persist   => true,
        }
    }
}
