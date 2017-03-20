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

    # core/mgmt routers
    $routers_defaults = {
        snmp_community => $passwords::network::snmp_ro_community,
        group          => 'routers',
        alarms         => true,
        interfaces     => true,
    }
    $routers = {
        # eqiad
        'cr1-eqiad' => { ipv4 => '208.80.154.196',  ipv6 => '2620:0:861:ffff::1', bgp => true, },
        'cr2-eqiad' => { ipv4 => '208.80.154.197',  ipv6 => '2620:0:861:ffff::2', bgp => true, },
        'mr1-eqiad' => { ipv4 => '208.80.154.199',  ipv6 => '2620:0:861:ffff::6', },
        'pfw-eqiad' => { ipv4 => '208.80.154.218',  },
        # eqord
        'cr1-eqord' => { ipv4 => '208.80.154.198',  ipv6 => '2620:0:861:ffff::5', bgp => true, },
        # codfw
        'cr1-codfw' => { ipv4 => '208.80.153.192',  ipv6 => '2620:0:860:ffff::1', bgp => true, },
        'cr2-codfw' => { ipv4 => '208.80.153.193',  ipv6 => '2620:0:860:ffff::2', bgp => true, },
        'mr1-codfw' => { ipv4 => '208.80.153.196',  ipv6 => '2620:0:860:ffff::6', },
        'pfw-codfw' => { ipv4 => '208.80.153.195',  },
        # eqdfw
        'cr1-eqdfw' => { ipv4 => '208.80.153.198',  ipv6 => '2620:0:860:ffff::5', bgp => true, },
        # esams
        'cr1-esams' => { ipv4 => '91.198.174.245',  ipv6 => '2620:0:862:ffff::5', bgp => true, },
        'cr2-esams' => { ipv4 => '91.198.174.244',  ipv6 => '2620:0:862:ffff::3', bgp => true, },
        'cr2-knams' => { ipv4 => '91.198.174.246',  ipv6 => '2620:0:862:ffff::4', bgp => true, },
        'mr1-esams' => { ipv4 => '91.198.174.247',  ipv6 => '2620:0:862:ffff::1', },
        # ulsfo
        'cr1-ulsfo' => { ipv4 => '198.35.26.192',   ipv6 => '2620:0:863:ffff::1', bgp => true, },
        'cr2-ulsfo' => { ipv4 => '198.35.26.193',   ipv6 => '2620:0:863:ffff::2', bgp => true, },
        'mr1-ulsfo' => { ipv4 => '198.35.26.194',   ipv6 => '2620:0:863:ffff::6',   },
    }
    create_resources(netops::check, $routers, $routers_defaults)

    # OOB interfaces -- no SNMP for these
    $oob = {
        'mr1-eqiad.oob' => { ipv4 => '198.32.107.153',  ipv6 => '2607:f6f0:205::153', },
        'mr1-codfw.oob' => { ipv4 => '216.117.46.36',   },
        'mr1-esams.oob' => { ipv4 => '164.138.24.90',   },
        'mr1-ulsfo.oob' => { ipv4 => '209.237.234.242', },
    }
    create_resources(netops::check, $oob)

    # access/management/peering switches
    $switches_defaults = {
        snmp_community => $passwords::network::snmp_ro_community,
        group          => 'switches',
        alarms         => true,
    }
    $switches = {
        # eqiad
        'asw-a-eqiad'   => { ipv4 => '10.65.0.17',   },
        'asw2-a5-eqiad' => { ipv4 => '10.65.0.20',   },
        'asw-b-eqiad'   => { ipv4 => '10.65.0.18',   },
        'asw-c-eqiad'   => { ipv4 => '10.65.0.23',   },
        'asw-d-eqiad'   => { ipv4 => '10.65.0.24',   },
        'asw2-d-eqiad'  => { ipv4 => '10.65.0.27',   },
        'msw1-eqiad'    => { ipv4 => '10.65.0.10',   },
        # codfw
        'asw-a-codfw'   => { ipv4 => '10.193.0.16',  },
        'asw-b-codfw'   => { ipv4 => '10.193.0.17',  },
        'asw-c-codfw'   => { ipv4 => '10.193.0.18',  },
        'asw-d-codfw'   => { ipv4 => '10.193.0.19',  },
        'msw1-codfw'    => { ipv4 => '10.193.0.3',   },
        # esams
        'asw-esams'     => { ipv4 => '10.21.0.104',  },
        'csw2-esams'    => { ipv4 => '10.21.0.105',  },
        # ulsfo
        'asw-ulsfo'     => { ipv4 => '10.128.128.6', },
    }
    create_resources(netops::check, $switches, $switches_defaults)
}
