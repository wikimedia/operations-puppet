# SPDX-License-Identifier: Apache-2.0
class profile::wmcs::cloud_private_subnet::bgp (
    Integer[0,4094]               $vlan_id     = lookup('profile::wmcs::cloud_private_subnet::vlan_id'),
    Stdlib::Fqdn                  $gw          = lookup('profile::wmcs::cloud_private_subnet::gw',      {'default_value' => 'cloudsw'}),
    Stdlib::Fqdn                  $domain      = lookup('profile::wmcs::cloud_private_subnet::domain',  {'default_value' => 'wikimedia.cloud'}),
    Stdlib::IP::Address::V4::Cidr $public_vips = lookup('profile::wmcs::cloud_private_subnet::public_vips'),
) {
    $cloud_private_fqdn = "${facts['hostname']}.private.${::site}.${domain}"
    $cloud_private_address = dnsquery::a($cloud_private_fqdn)[0]

    $gw_fqdn = "${gw}.private.${::site}.${domain}"
    $gw_address = dnsquery::a($gw_fqdn)[0]

    $interface = "vlan${vlan_id}"

    class { 'profile::bird::anycast':
        neighbors_list => [$gw_address],
        ipv4_src       => $cloud_private_address,
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

    interface::post_up_command { "${table}_route_lookup_rule":
        interface => $interface,
        command   => "ip rule add from ${public_vips} table ${table}",
    }
}
