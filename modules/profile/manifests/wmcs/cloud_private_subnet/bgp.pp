# SPDX-License-Identifier: Apache-2.0
class profile::wmcs::cloud_private_subnet::bgp (
    Stdlib::Fqdn                        $cloud_private_host = lookup('profile::wmcs::cloud_private_subnet::host'),
    String[1]                           $cloud_private_gw_t = lookup('profile::wmcs::cloud_private_subnet::gw_template'),
    Integer[0,4094]                     $vlan_id            = lookup('profile::wmcs::cloud_private_subnet::vlan_id'),
    Hash[String, Wmflib::Advertise_vip] $vips               = lookup('profile::bird::advertise_vips',                { 'merge' => 'hash' }),
    Netbox::Device::Location            $netbox_location    = lookup('profile::netbox::host::location'),
) {
    $cloud_private_address = dnsquery::a($cloud_private_host)[0]
    $cloud_private_gw = inline_epp($cloud_private_gw_t, { 'rack' => downcase($netbox_location['rack']) })
    $gw_address = dnsquery::a($cloud_private_gw)[0]

    $interface = "vlan${vlan_id}"

    class { 'profile::bird::anycast':
        advertise_vips => $vips,  # we did a merge, the base profile does a simple lookup
        neighbors_list => [$gw_address],
        ipv4_src       => $cloud_private_address,
        multihop       => false,
    }

    $table = 'cloud-private'
    $table_number = 100

    file { "/etc/iproute2/rt_tables.d/${table}.conf":
        ensure  => present,
        content => "${table_number} ${table}\n",
    }

    interface::post_up_command { "${table}_default_gw":
        interface => $interface,
        command   => "ip route add default via ${gw_address} table ${table}",
    }

    $vips.each |$entry_name, $vip_info| {
        interface::post_up_command { "${table}_route_lookup_rule_${entry_name}":
            interface => $interface,
            command   => "ip rule add from ${vip_info['address']}/32 table ${table}",
        }
    }
}
