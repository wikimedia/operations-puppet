# SPDX-License-Identifier: Apache-2.0
class profile::wmcs::cloud_private_subnet (
    Stdlib::Fqdn                  $domain      = lookup('profile::wmcs::cloud_private_subnet::domain',  {'default_value' => 'wikimedia.cloud'}),
    Integer[1,32]                 $netmask     = lookup('profile::wmcs::cloud_private_subnet::netmask', {'default_value' => 24}),
    Stdlib::Fqdn                  $gw          = lookup('profile::wmcs::cloud_private_subnet::gw',      {'default_value' => 'cloudsw'}),
    Integer[0,4094]               $vlan_id     = lookup('profile::wmcs::cloud_private_subnet::vlan_id'),
    Stdlib::IP::Address::V4::Cidr $supernet    = lookup('profile::wmcs::cloud_private_subnet::supernet'),
    Stdlib::IP::Address::V4::Cidr $public_vips = lookup('profile::wmcs::cloud_private_subnet::public_vips'),
    String                        $base_iface  = lookup('profile::wmcs::cloud_private_subnet::base_iface', {'default_value' => 'primary'}),
) {
    $cloud_private_fqdn = "${facts['hostname']}.private.${::site}.${domain}"
    $cloud_private_address = dnsquery::a($cloud_private_fqdn)[0]

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

    $gw_fqdn = "${gw}.private.${::site}.${domain}"
    $gw_address = dnsquery::a($gw_fqdn)[0]

    interface::route { 'cloud_private_subnet_route':
        address   => split($supernet, '/')[0],
        prefixlen => split($supernet, '/')[1],
        nexthop   => $gw_address,
        interface => $interface,
    }

    interface::route { 'cloud_private_subnet_public_vips_route':
        address   => split($public_vips, '/')[0],
        prefixlen => split($public_vips, '/')[1],
        nexthop   => $gw_address,
        interface => $interface,
    }
}
