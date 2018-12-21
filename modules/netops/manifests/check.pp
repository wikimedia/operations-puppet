# == Define: netops::check
#
# Sets up various monitoring checks for a given networking device.
#
# === Parameters
#
# [*ipv4*]
#   The IPv4 address of the device. Required.
#
# [*ipv6*]
#   The IPv6 address of the device. Optional.
#
# [*snmp_community*]
#   The SNMP community to use to poll the device. Optional
#
# [*alarms*]
#   Whether to perform chassis alarms checks. Defaults to false.
#
# [*interfaces*]
#   Whether to perform interface status checks. Defaults to false.
#
# [*bgp*]
#   Whether to perform BGP checks. Defaults to false.
#
# [*parents*]
#   The parent devices of this device. Accepts either an array or a comma
#   separate string. Defaults to undef
#
# [*os*]
#   The operating system of the device. Defaults to undef.
#
# === Examples
#
#  netops::check { 'cr1-esams':
#      ipv4 => '91.198.174.245',
#      bgp  => true,
#  }

define netops::check(
    $ipv4,
    $ipv6=undef,
    $snmp_community=undef,
    $group='network',
    $alarms=false,
    $bgp=false,
    $interfaces=false,
    $parents=undef,
    $os=undef,
    $vcp=false,
    $vrrp_peer=false,
) {

    # If we get an array convert it to a comma separated string
    if $parents and is_array($parents) {
        $real_parents = join($parents, ',')
    # Otherwise, pass it as is (undef or string)
    } else {
        $real_parents = $parents
    }

    @monitoring::host { $title:
        ip_address => $ipv4,
        group      => $group,
        parents    => $real_parents,
        os         => $os,
    }

    if $ipv6 {
        @monitoring::host { "${title} IPv6":
            ip_address => $ipv6,
            group      => $group,
        }
    }

    if $alarms {
      $monitor_enable='present'
    } else {
      $monitor_enable='absent'
    }
    @monitoring::service { "${title} Juniper alarms":
        ensure        => $monitor_enable,
        host          => $title,
        group         => $group,
        description   => 'Juniper alarms',
        check_command => "check_jnx_alarms!${snmp_community}",
        notes_url     => 'https://wikitech.wikimedia.org/wiki/Network_monitoring#Juniper_alarm',
    }

    if $interfaces {
        @monitoring::service { "${title} interfaces":
            host          => $title,
            group         => $group,
            description   => 'Router interfaces',
            check_command => "check_ifstatus_nomon!${snmp_community}",
            notes_url     => 'https://wikitech.wikimedia.org/wiki/Network_monitoring#Router_interface_down',
        }
    }

    if $bgp {
        @monitoring::service { "${title} BGP status":
            host          => $title,
            group         => $group,
            description   => 'BGP status',
            check_command => "check_bgp!${snmp_community}",
            notes_url     => 'https://wikitech.wikimedia.org/wiki/Network_monitoring#BGP_status',
        }
    }

    if $vcp {
        @monitoring::service { "${title} VCP status":
            host          => $title,
            group         => $group,
            description   => 'Juniper virtual chassis ports',
            check_command => "check_vcp!${snmp_community}",
            notes_url     => 'https://wikitech.wikimedia.org/wiki/Network_monitoring#VCP_status',
        }
    }

    if $vrrp_peer {
        @monitoring::service { "${title} VRRP status":
            host          => $title,
            group         => $group,
            description   => 'VRRP status',
            check_command => "check_vrrp!${vrrp_peer}!${snmp_community}",
            notes_url     => 'https://wikitech.wikimedia.org/wiki/Network_monitoring#VRRP_status',
        }
    }
}
