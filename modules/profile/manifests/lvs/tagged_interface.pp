# SPDX-License-Identifier: Apache-2.0
define profile::lvs::tagged_interface(
    Hash[String, Hash] $interfaces,
    Boolean $ipip_enabled,
) {
    $vlan_info = $interfaces[$title]
    $vlan_id = $vlan_info['id']
    if $::hostname in $vlan_info['iface'] {
        $iface_str = $vlan_info['iface'][$::hostname]
        $iface = split($iface_str, ':')
        $tag = "${iface[0]}.${vlan_id}"

        interface::tagged { $tag:
            base_interface     => $iface[0],
            vlan_id            => $vlan_id,
            address            => $iface[1],
            netmask            => $vlan_info['netmask'],
            legacy_vlan_naming => false,
        }

        interface::clsact { $tag:
            ensure    => stdlib::ensure($ipip_enabled),
            interface => "vlan${vlan_id}",
        }
    }
}
