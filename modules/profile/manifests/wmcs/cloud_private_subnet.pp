# SPDX-License-Identifier: Apache-2.0
class profile::wmcs::cloud_private_subnet (
    Integer                       $vlan_id = lookup('profile::wmcs::cloud_private_subnet::vlan_id'),
    Stdlib::IP::Address::V4::Cidr $address = lookup('profile::wmcs::cloud_private_subnet::address'),
) {
    interface::tagged { 'cloud_private_subnet_iface':
        base_interface     => $facts['interface_primary'],
        vlan_id            => $vlan_id,
        method             => 'manual',
        up                 => 'ip link set $IFACE up',
        down               => 'ip link set $IFACE down',
        legacy_vlan_naming => false,
    }

    $ip = split($address, '/')[0]
    $netmask = split($address, '/')[1]

    interface::ip { 'cloud_private_subnet_ip':
        interface => "vlan${vlan_id}",
        address   => $ip,
        prefixlen => $netmask,
    }
}
