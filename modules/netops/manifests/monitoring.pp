# == Class: netops::monitoring
#
# Sets up monitoring checks for networking equipment.
#
# === Parameters
#
# === Examples
#
#  include netops::monitoring

class netops::monitoring {
    include passwords::network

    $defaults = {
        snmp_community => $passwords::network::snmp_ro_community,
        alarms         => true,
        interfaces     => true,
    }
    $routers = {
        # eqiad
        'cr1-eqiad'     => { ipv4 => '208.80.154.196', bgp => true, },
        'cr2-eqiad'     => { ipv4 => '208.80.154.197', bgp => true, },
        'mr1-eqiad'     => { ipv4 => '208.80.154.199', },
        'mr1-eqiad.oob' => { ipv4 => '198.32.107.153', },
        # eqord
        'cr1-eqord'     => { ipv4 => '208.80.154.198', bgp => true, },
        # codfw
        'cr1-codfw'     => { ipv4 => '208.80.153.192', bgp => true, },
        'cr2-codfw'     => { ipv4 => '208.80.153.193', bgp => true, },
        'mr1-codfw'     => { ipv4 => '208.80.153.196', },
        'mr1-codfw.oob' => { ipv4 => '216.117.46.36',  },
        # eqdfw
        'cr1-eqdfw'     => { ipv4 => '208.80.153.198', bgp => true, },
        # esams
        'cr1-esams'     => { ipv4 => '91.198.174.245', bgp => true, },
        'cr2-esams'     => { ipv4 => '91.198.174.244', bgp => true, },
        'cr2-knams'     => { ipv4 => '91.198.174.246', bgp => true, },
        'mr1-esams'     => { ipv4 => '91.198.174.247', },
        'mr1-esams.oob' => { ipv4 => '164.138.24.90',  },
        # ulsfo
        'cr1-ulsfo'     => { ipv4 => '198.35.26.192', bgp => true, },
        'cr2-ulsfo'     => { ipv4 => '198.35.26.193', bgp => true, },
        'mr1-ulsfo'     => { ipv4 => '198.35.26.194',   },
        'mr1-ulsfo.oob' => { ipv4 => '209.237.234.242', },
    }
    create_resources(netops::check, $routers, $defaults)
}
