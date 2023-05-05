# SPDX-License-Identifier: Apache-2.0
class profile::wmcs::cloud_private_subnet (
    Boolean                       $do_bgp      = lookup('profile::wmcs::cloud_private_subnet::do_bgp',  {'default_value' => false}),
    Stdlib::Fqdn                  $domain      = lookup('profile::wmcs::cloud_private_subnet::domain',  {'default_value' => 'hw.wikimedia.cloud'}),
    Integer[1,32]                 $netmask     = lookup('profile::wmcs::cloud_private_subnet::netmask', {'default_value' => 24}),
    Stdlib::Fqdn                  $gw          = lookup('profile::wmcs::cloud_private_subnet::gw',      {'default_value' => 'cloudsw'}),
    Integer[0,4094]               $vlan_id     = lookup('profile::wmcs::cloud_private_subnet::vlan_id'),
    Stdlib::IP::Address::V4::Cidr $supernet    = lookup('profile::wmcs::cloud_private_subnet::supernet'),
    Stdlib::IP::Address::V4::Cidr $public_vips = lookup('profile::wmcs::cloud_private_subnet::public_vips'),
) {

    $cloud_private_fqdn = "${facts['hostname']}.${::site}.${domain}"
    $cloud_private_address = dnsquery::a($cloud_private_fqdn)[0]

    interface::tagged { 'cloud_private_subnet_iface':
        base_interface     => $facts['interface_primary'],
        vlan_id            => $vlan_id,
        method             => 'manual',
        up                 => 'ip link set $IFACE up',
        down               => 'ip link set $IFACE down',
        legacy_vlan_naming => false,
    }

    interface::ip { 'cloud_private_subnet_ip':
        interface => "vlan${vlan_id}",
        address   => $cloud_private_address,
        prefixlen => $netmask,
    }

    $gw_fqdn = "${gw}.${::site}.${domain}"
    $gw_address = dnsquery::a($gw_fqdn)[0]

    interface::route { 'cloud_private_subnet_route':
        address   => split($supernet, '/')[0],
        prefixlen => split($supernet, '/')[1],
        nexthop   => $gw_address,
        interface => "vlan${vlan_id}",
    }

    interface::route { 'cloud_private_subnet_public_vips_route':
        address   => split($public_vips, '/')[0],
        prefixlen => split($public_vips, '/')[1],
        nexthop   => $gw_address,
        interface => "vlan${vlan_id}",
    }

    if $do_bgp {
        class { 'profile::bird::anycast':
            neighbors_list => [$gw_address],
            ipv4_src       => $cloud_private_address,
        }
    }
}
