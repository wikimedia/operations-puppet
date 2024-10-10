# SPDX-License-Identifier: Apache-2.0
# @summary Sets up monitoring checks for networking equipment.
# @param infra_devices A hash of devices
# @example include netops::monitoring

class netops::monitoring(
    Wmflib::Infra::Devices $infra_devices,
) {
    include passwords::network

    $routers_defaults = {
        snmp_community => $passwords::network::snmp_ro_community,
        alarms         => false,
        critical       => true,
        interfaces     => true,
        bfd            => true,
        bgp            => true,
        os             => 'Junos',
        ospf           => true,
    }

    #############################################################################################################
    ###### WARNING WARNING WARNING WARNING WARNING WARNING WARNING WARNING WARNING WARNING WARNING WARNING ######
    ######                                                                                                 ######
    ###### profile::druid::turnilo makes use of the information populated in $routers via puppetdb_query.  ######
    ###### One needs to ensure any changes made here are compatible with the use case in that profile      ######
    ###### specifically we use the following so the bgp and bfd attributes are significant:                ######
    ######     resources[certname, parameters, title] {                                                    ######
    ######         type = "Netops::Check                                                                   ######
    ######         and parameters.bgp = true and parameters.bfd = true                                     ######
    ######         order by certname                                                                       ######
    ######     }                                                                                           ######
    ###### WARNING WARNING WARNING WARNING WARNING WARNING WARNING WARNING WARNING WARNING WARNING WARNING ######
    #############################################################################################################

    $routers = $infra_devices.filter |$device, $config| {
        $config['role'] in ['cr', 'pfw']
    }
    create_resources(netops::check, $routers, $routers_defaults)

    # mgmt routers
    $mgmt_routers_defaults = {
        snmp_community => $passwords::network::snmp_ro_community,
        alarms         => true,
        interfaces     => true,
        os             => 'Junos',
        ospf           => true,
    }
    $mgmt_routers = $infra_devices.filter |$device, $config| {
        $config['role'] == 'mr'
    }
    create_resources(netops::check, $mgmt_routers, $mgmt_routers_defaults)

    # OOB interfaces -- no SNMP for these
    $oob = {
        'mr1-eqiad.oob' => { ipv4 => '149.97.228.94',  ipv6 => '2607:f6f0:1000:1194::2', parents => ['mr1-eqiad'] },
        'mr1-codfw.oob' => { ipv4 => '216.117.46.36', parents => ['mr1-codfw'] },
        'mr1-esams.oob' => { ipv4 => '185.27.16.142', ipv6 => '2a00:1188:5:e::4', parents => ['mr1-esams'] },
        'mr1-ulsfo.oob' => { ipv4 => '198.24.47.102',   ipv6 => '2607:fb58:9000:7::2',  parents => ['mr1-ulsfo'] },
        'mr1-eqsin.oob' => { ipv4 => '27.111.227.106',  ipv6 => '2403:b100:3001:9::2',  parents => ['mr1-eqsin'] },
        'mr1-drmrs.oob' => { ipv4 => '193.251.154.146',  ipv6 => '2001:688:0:4::2d4',  parents => ['mr1-drmrs'] },
        'mr1-magru.oob' => { ipv4 => '177.185.14.4',  ipv6 => '2804:ad4:ff12:19::84',  parents => ['mr1-magru'] },
        're0.cr1-eqiad.mgmt' => { ipv4 => '10.65.0.12',      parents => ['msw1-eqiad'] },
        're0.cr2-eqiad.mgmt' => { ipv4 => '10.65.0.14',      parents => ['msw1-eqiad'] },
        're0.cr1-codfw.mgmt' => { ipv4 => '10.193.0.10',     parents => ['msw1-codfw'] },
        're0.cr2-codfw.mgmt' => { ipv4 => '10.193.0.12',     parents => ['msw1-codfw'] },
        'cr2-esams.mgmt' => { ipv4 => '10.80.128.19',     parents => ['mr1-esams'] },
        're0.cr1-esams.mgmt' => { ipv4 => '10.80.128.2',     parents => ['mr1-esams'] },
        'cr3-ulsfo.mgmt' => { ipv4 => '10.128.128.4',    parents => ['mr1-ulsfo'] },
        'cr4-ulsfo.mgmt' => { ipv4 => '10.128.128.5',    parents => ['mr1-ulsfo'] },
        'cr3-eqsin.mgmt' => { ipv4 => '10.132.128.7',    parents => ['mr1-eqsin'] },
        'cr2-eqsin.mgmt' => { ipv4 => '10.132.128.6',    parents => ['mr1-eqsin'] },
        'cr1-drmrs.mgmt' => { ipv4 => '10.136.128.6',    parents => ['mr1-drmrs'] },
        'cr2-drmrs.mgmt' => { ipv4 => '10.136.128.7',    parents => ['mr1-drmrs'] },
    }
    create_resources(netops::check, $oob)

    #
    # Management switches
    #
    $mgmt_switches_defaults = {
        snmp_community => $passwords::network::snmp_ro_community,
        alarms         => true,
        os             => 'Junos',
    }
    $mgmt_switches = $infra_devices.filter |$device, $config| {
        $config['role'] == 'msw'
    }
    create_resources(netops::check, $mgmt_switches, $mgmt_switches_defaults)

    #
    # L2 only "legacy" switches
    #
    # Note: The parents attribute is used to capture a view of the network
    # topology. It is not complete on purpose as icinga is not able to
    # work well with loops.
    #
    $switches_defaults = {
        snmp_community => $passwords::network::snmp_ro_community,
        alarms         => true,
        os             => 'Junos',
        vcp            => true,
    }
    $switches = $infra_devices.filter |$device, $config| {
        $config['role'] == 'l2sw'
    }
    create_resources(netops::check, $switches, $switches_defaults)

    #
    # L3 switches (data plane interface)
    #
    # Those devices have both mgmt and data plane IPs (usually loopback)
    # The dataplane IP is used for parent/child relationship, as well as checking basic connectivity.
    # This is also the name automatically used for servers' parents using LLDP.
    #
    $l3_switches_defaults = {
        os => 'Junos',
    }
    $l3_switches = $infra_devices.filter |$device, $config| {
        $config['role'] == 'l3sw'
    }
    create_resources(netops::check, $l3_switches, $l3_switches_defaults)

    #
    # L3 switches (mgmt interface)
    #
    # The mgmt IP is used to run extra checks via SNMP in adition to checking mgmt reachability.
    #
    $l3_switches_mgmt_defaults = {
        snmp_community => $passwords::network::snmp_ro_community,
        alarms         => true,
        bgp            => true,
        bfd            => true,  # Will report as OK if no BFD is in use
        ospf           => true,  # Will report as OK if no OSPF in use
        os             => 'Junos',
    }
    $l3_switches_mgmt = {
        # eqiad cloud
        'cloudsw1-c8-eqiad.mgmt' => { ipv4 => '10.65.0.7', parents => ['msw1-eqiad']},
        'cloudsw1-d5-eqiad.mgmt' => { ipv4 => '10.65.0.6', parents => ['msw1-eqiad']},
        'cloudsw2-d5-eqiad.mgmt' => { ipv4 => '10.65.1.198', parents => ['msw1-eqiad'], bgp => false},
        'cloudsw1-e4-eqiad.mgmt' => { ipv4 => '10.65.1.231', parents => ['msw2-eqiad']},
        'cloudsw1-f4-eqiad.mgmt' => { ipv4 => '10.65.1.235', parents => ['msw2-eqiad']},
        # eqiad prod
        'ssw1-e1-eqiad.mgmt' => { ipv4 => '10.65.2.143', parents => ['msw2-eqiad'] },
        'lsw1-e1-eqiad.mgmt' => { ipv4 => '10.65.1.228', parents => ['msw2-eqiad'] },
        'lsw1-e2-eqiad.mgmt' => { ipv4 => '10.65.1.229', parents => ['msw2-eqiad'] },
        'lsw1-e3-eqiad.mgmt' => { ipv4 => '10.65.1.230', parents => ['msw2-eqiad'] },
        'lsw1-e5-eqiad.mgmt' => { ipv4 => '10.65.7.109', parents => ['msw2-eqiad'] },
        'lsw1-e6-eqiad.mgmt' => { ipv4 => '10.65.7.110', parents => ['msw2-eqiad'] },
        'lsw1-e7-eqiad.mgmt' => { ipv4 => '10.65.7.111', parents => ['msw2-eqiad'] },
        'ssw1-f1-eqiad.mgmt' => { ipv4 => '10.65.2.144', parents => ['msw2-eqiad'] },
        'lsw1-f1-eqiad.mgmt' => { ipv4 => '10.65.1.232', parents => ['msw2-eqiad'] },
        'lsw1-f2-eqiad.mgmt' => { ipv4 => '10.65.1.233', parents => ['msw2-eqiad'] },
        'lsw1-f3-eqiad.mgmt' => { ipv4 => '10.65.1.234', parents => ['msw2-eqiad'] },
        'lsw1-f5-eqiad.mgmt' => { ipv4 => '10.65.7.112', parents => ['msw2-eqiad'] },
        'lsw1-f6-eqiad.mgmt' => { ipv4 => '10.65.7.113', parents => ['msw2-eqiad'] },
        'lsw1-f7-eqiad.mgmt' => { ipv4 => '10.65.7.114', parents => ['msw2-eqiad'] },
        # codfw prod
        'ssw1-a1-codfw.mgmt' => { ipv4 => '10.193.1.204', parents => ['msw1-codfw'] },
        'ssw1-a8-codfw.mgmt' => { ipv4 => '10.193.2.1', parents => ['msw1-codfw'] },
        'ssw1-d1-codfw.mgmt' => { ipv4 => '10.193.2.208', parents => ['msw1-codfw'] },
        'ssw1-d8-codfw.mgmt' => { ipv4 => '10.193.2.210', parents => ['msw1-codfw'] },
        'lsw1-a2-codfw.mgmt' => { ipv4 => '10.193.1.207', parents => ['msw1-codfw'] },
        'lsw1-a3-codfw.mgmt' => { ipv4 => '10.193.2.18', parents => ['msw1-codfw'] },
        'lsw1-a4-codfw.mgmt' => { ipv4 => '10.193.2.19', parents => ['msw1-codfw'] },
        'lsw1-a5-codfw.mgmt' => { ipv4 => '10.193.2.20', parents => ['msw1-codfw'] },
        'lsw1-a6-codfw.mgmt' => { ipv4 => '10.193.2.21', parents => ['msw1-codfw'] },
        'lsw1-a7-codfw.mgmt' => { ipv4 => '10.193.2.22', parents => ['msw1-codfw'] },
        'lsw1-a8-codfw.mgmt' => { ipv4 => '10.193.2.23', parents => ['msw1-codfw'] },
        'lsw1-b2-codfw.mgmt' => { ipv4 => '10.193.2.73', parents => ['msw1-codfw'] },
        'lsw1-b3-codfw.mgmt' => { ipv4 => '10.193.2.74', parents => ['msw1-codfw'] },
        'lsw1-b4-codfw.mgmt' => { ipv4 => '10.193.2.75', parents => ['msw1-codfw'] },
        'lsw1-b5-codfw.mgmt' => { ipv4 => '10.193.2.76', parents => ['msw1-codfw'] },
        'lsw1-b6-codfw.mgmt' => { ipv4 => '10.193.2.77', parents => ['msw1-codfw'] },
        'lsw1-b7-codfw.mgmt' => { ipv4 => '10.193.2.78', parents => ['msw1-codfw'] },
        'lsw1-b8-codfw.mgmt' => { ipv4 => '10.193.2.79', parents => ['msw1-codfw'] },
        'lsw1-c1-codfw.mgmt' => { ipv4 => '10.193.1.154', parents => ['msw1-codfw'] },
        'lsw1-c2-codfw.mgmt' => { ipv4 => '10.193.2.211', parents => ['msw1-codfw'] },
        'lsw1-c3-codfw.mgmt' => { ipv4 => '10.193.1.232', parents => ['msw1-codfw'] },
        'lsw1-c4-codfw.mgmt' => { ipv4 => '10.193.1.233', parents => ['msw1-codfw'] },
        'lsw1-c5-codfw.mgmt' => { ipv4 => '10.193.1.231', parents => ['msw1-codfw'] },
        'lsw1-c6-codfw.mgmt' => { ipv4 => '10.193.1.234', parents => ['msw1-codfw'] },
        'lsw1-c7-codfw.mgmt' => { ipv4 => '10.193.2.2', parents => ['msw1-codfw'] },
        'lsw1-d1-codfw.mgmt' => { ipv4 => '10.193.1.205', parents => ['msw1-codfw'] },
        'lsw1-d2-codfw.mgmt' => { ipv4 => '10.193.2.80', parents => ['msw1-codfw'] },
        'lsw1-d3-codfw.mgmt' => { ipv4 => '10.193.2.118', parents => ['msw1-codfw'] },
        'lsw1-d4-codfw.mgmt' => { ipv4 => '10.193.2.152', parents => ['msw1-codfw'] },
        'lsw1-d5-codfw.mgmt' => { ipv4 => '10.193.2.174', parents => ['msw1-codfw'] },
        'lsw1-d6-codfw.mgmt' => { ipv4 => '10.193.2.186', parents => ['msw1-codfw'] },
        'lsw1-d7-codfw.mgmt' => { ipv4 => '10.193.2.192', parents => ['msw1-codfw'] },
        'lsw1-d8-codfw.mgmt' => { ipv4 => '10.193.2.207', parents => ['msw1-codfw'] },
        # codfw cloud
        'cloudsw1-b1-codfw.mgmt' => { ipv4 => '10.193.0.243', parents => ['msw1-codfw']},
        # drmrs
        'asw1-b12-drmrs.mgmt' => { ipv4 => '10.136.128.3',   parents => ['mr1-drmrs'] },
        'asw1-b13-drmrs.mgmt' => { ipv4 => '10.136.128.4',   parents => ['mr1-drmrs'] },
        # esams
        'asw1-bw27-esams.mgmt' => { ipv4 => '10.80.128.3',   parents => ['mr1-esams'] },
        'asw1-by27-esams.mgmt' => { ipv4 => '10.80.128.5',   parents => ['mr1-esams'] },
        # magru
        'asw1-b3-magru.mgmt' => { ipv4 => '10.140.128.4',   parents => ['mr1-magru'] },
        'asw1-b4-magru.mgmt' => { ipv4 => '10.140.128.5',   parents => ['mr1-magru'] },
    }
    create_resources(netops::check, $l3_switches_mgmt, $l3_switches_mgmt_defaults)


    # RIPE Atlases -- no SNMP for these
    $atlas = $infra_devices.filter |$device, $config| {
        $config['role'] == 'atlas'
    }
    create_resources(netops::check, $atlas)

    # RIPE Atlases -- ping checks from prometheus blackbox
    $atlas_blackbox_exporter = $atlas.map |$device, $config| {
        {
          "${device}" => {
            'instance_label'      => $device,
            'ip4'                 => $config['ipv4'],
            'ip6'                 => $config['ipv6'],
            'site'                => $config['site'],
            'prometheus_instance' => 'ops'
          }
        }
    }.reduce( {} ) | $memo, $x | {
      $memo + $x
    }
    create_resources(prometheus::blackbox::check::icmp, $atlas_blackbox_exporter)

    # RIPE Atlases measurements checks moved to prometheus/alertmanar

    # SCS -- Serial Console Servers
    $scs = $infra_devices.filter |$device, $config| {
        $config['role'] == 'scs'
    }
    create_resources(netops::check, $scs)
}
