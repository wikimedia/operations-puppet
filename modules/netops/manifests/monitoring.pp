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
        alarms         => true,
        interfaces     => true,
        os             => 'Junos',
    }
    $routers = {
        # eqiad
        'cr1-eqiad'  => { ipv4 => '208.80.154.196',  ipv6 => '2620:0:861:ffff::1', bgp => true, },
        'cr2-eqiad'  => { ipv4 => '208.80.154.197',  ipv6 => '2620:0:861:ffff::2', bgp => true, },
        'mr1-eqiad'  => { ipv4 => '208.80.154.199',  ipv6 => '2620:0:861:ffff::6', },
        'pfw3-eqiad'  => { ipv4 => '208.80.154.219', parents => ['cr1-eqiad', 'cr2-eqiad'], bgp => true, alarms => false, },
        # eqord
        'cr1-eqord'  => { ipv4 => '208.80.154.198',  ipv6 => '2620:0:861:ffff::5', bgp => true, },
        # codfw
        'cr1-codfw'  => { ipv4 => '208.80.153.192',  ipv6 => '2620:0:860:ffff::1', bgp => true, },
        'cr2-codfw'  => { ipv4 => '208.80.153.193',  ipv6 => '2620:0:860:ffff::2', bgp => true, },
        'mr1-codfw'  => { ipv4 => '208.80.153.196',  ipv6 => '2620:0:860:ffff::6', },
        'pfw3-codfw' => { ipv4 => '208.80.153.197',  parents => ['cr1-codfw', 'cr2-codfw'], bgp => true, alarms => false, },
        # eqdfw
        'cr1-eqdfw'  => { ipv4 => '208.80.153.198',  ipv6 => '2620:0:860:ffff::5', bgp => true, },
        # esams
        'cr1-esams'  => { ipv4 => '91.198.174.245',  ipv6 => '2620:0:862:ffff::5', bgp => true, },
        'cr2-esams'  => { ipv4 => '91.198.174.244',  ipv6 => '2620:0:862:ffff::3', bgp => true, },
        'cr2-knams'  => { ipv4 => '91.198.174.246',  ipv6 => '2620:0:862:ffff::4', bgp => true, },
        'mr1-esams'  => { ipv4 => '91.198.174.247',  ipv6 => '2620:0:862:ffff::1', },
        # ulsfo
        'cr1-ulsfo'  => { ipv4 => '198.35.26.192',   ipv6 => '2620:0:863:ffff::1', bgp => true, },
        'cr2-ulsfo'  => { ipv4 => '198.35.26.193',   ipv6 => '2620:0:863:ffff::2', bgp => true, },
        'mr1-ulsfo'  => { ipv4 => '198.35.26.194',   ipv6 => '2620:0:863:ffff::6',   },
        # eqsin
        'mr1-eqsin'  => { ipv4 => '103.102.166.128', ipv6 => '2001:df2:e500:ffff::1', },
        'cr1-eqsin'  => { ipv4 => '103.102.166.129', ipv6 => '2001:df2:e500:ffff::2', bgp => true, },
    }
    create_resources(netops::check, $routers, $routers_defaults)

    # OOB interfaces -- no SNMP for these
    $oob = {
        'mr1-eqiad.oob' => { ipv4 => '198.32.107.153',  ipv6 => '2607:f6f0:205::153', },
        'mr1-codfw.oob' => { ipv4 => '216.117.46.36',   },
        'mr1-esams.oob' => { ipv4 => '164.138.24.90',   },
        'mr1-ulsfo.oob' => { ipv4 => '209.237.234.242', },
        'mr1-eqsin.oob' => { ipv4 => '27.111.227.106',  ipv6 => '2403:b100:3001:9::2', },
        're0.cr1-eqiad' => { ipv4 => '10.65.0.12',      parents => ['mr1-eqiad'] },
        're0.cr2-eqiad' => { ipv4 => '10.65.0.14',      parents => ['mr1-eqiad'] },
        're0.cr1-codfw' => { ipv4 => '10.193.0.10',     parents => ['mr1-codfw'] },
        're0.cr2-codfw' => { ipv4 => '10.193.0.12',     parents => ['mr1-codfw'] },
        're0.cr1-esams' => { ipv4 => '10.21.0.116',     parents => ['mr1-esams'] },
        're0.cr2-esams' => { ipv4 => '10.21.0.117',     parents => ['mr1-esams'] },
        're0.cr1-ulsfo' => { ipv4 => '10.128.128.2',    parents => ['mr1-ulsfo'] },
        're0.cr2-ulsfo' => { ipv4 => '10.128.128.3',    parents => ['mr1-ulsfo'] },
        're0.cr1-eqsin' => { ipv4 => '10.132.128.2',    parents => ['mr1-eqsin'] },

    }
    create_resources(netops::check, $oob)

    # access/management/peering switches
    $switches_defaults = {
        snmp_community => $passwords::network::snmp_ro_community,
        alarms         => true,
        os             => 'Junos',
    }
    # Note: The parents attribute is used to capture a view of the network
    # topology. It is not complete on purpose as icinga is not able to
    # work well with loops
    $switches = {
        # eqiad
        'asw-a-eqiad'   => { ipv4 => '10.65.0.17',   parents => ['cr1-eqiad', 'cr2-eqiad'] },
        'asw2-a5-eqiad' => { ipv4 => '10.65.0.20',   parents => ['cr1-eqiad', 'cr2-eqiad'] },
        'asw-b-eqiad'   => { ipv4 => '10.65.0.18',   parents => ['cr1-eqiad', 'cr2-eqiad'] },
        'asw-c-eqiad'   => { ipv4 => '10.65.0.23',   parents => ['cr1-eqiad', 'cr2-eqiad'] },
        'asw2-d-eqiad'  => { ipv4 => '10.65.0.27',   parents => ['cr1-eqiad', 'cr2-eqiad'] },
        'msw1-eqiad'    => { ipv4 => '10.65.0.10',   parents => ['cr1-eqiad', 'cr2-eqiad'] },
        'fasw-c-eqiad'  => { ipv4 => '10.65.0.30',   parents => ['pfw3-eqiad'] },
        # codfw
        'asw-a-codfw'   => { ipv4 => '10.193.0.16',  parents => ['cr1-codfw', 'cr2-codfw'] },
        'asw-b-codfw'   => { ipv4 => '10.193.0.17',  parents => ['cr1-codfw', 'cr2-codfw'] },
        'asw-c-codfw'   => { ipv4 => '10.193.0.18',  parents => ['cr1-codfw', 'cr2-codfw'] },
        'asw-d-codfw'   => { ipv4 => '10.193.0.19',  parents => ['cr1-codfw', 'cr2-codfw'] },
        'msw1-codfw'    => { ipv4 => '10.193.0.3',   parents => ['cr1-codfw', 'cr2-codfw'] },
        'fasw-c-codfw'  => { ipv4 => '10.193.0.57',  parents => ['pfw3-codfw'] },
        # esams
        'asw-esams'     => { ipv4 => '10.21.0.104',  parents => ['cr1-esams', 'cr2-esams'] },
        'csw2-esams'    => { ipv4 => '10.21.0.105',  parents => ['asw-esams']  },
        # ulsfo
        'asw2-ulsfo'    => { ipv4 => '10.128.128.7', parents => ['cr1-ulsfo', 'cr2-ulsfo'] },
        # eqsin
        'asw1-eqsin'    => { ipv4 => '10.132.128.4', parents => ['cr1-eqsin'] },
    }
    create_resources(netops::check, $switches, $switches_defaults)

    # RIPE Atlases -- no SNMP for these
    $atlas = {
        'ripe-atlas-eqiad' => { ipv4 => '208.80.155.69',  ipv6 => '2620:0:861:202:208:80:155:69',  },
        'ripe-atlas-codfw' => { ipv4 => '208.80.152.244', ipv6 => '2620:0:860:201:208:80:152:244', },
        'ripe-atlas-ulsfo' => { ipv4 => '198.35.26.244',  ipv6 => '2620:0:863:201:198:35:26:244',  },
    }
    create_resources(netops::check, $atlas)

    # RIPE Atlas Anchor measurements -- implicit dependency on the above host checks
    $atlas_measurements = {
        'eqiad' => { ipv4 => '1790945', ipv6 => '1790947', },
        'codfw' => { ipv4 => '1791210', ipv6 => '1791212', },
        'ulsfo' => { ipv4 => '1791307', ipv6 => '1791309', },
    }
    create_resources(netops::ripeatlas, $atlas_measurements)
}
