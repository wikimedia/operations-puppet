# SPDX-License-Identifier: Apache-2.0
# monitoring of non-server data center
# hardware like power distribution units and cameras
class facilities (
    Hash[String, String] $mgmt_parents = {}
) {

    # The PDUs are queried over SNMP using the snmp command provided by the snmp
    # package. For now ensure it here but it may need to be put in another place
    # in the future
    ensure_packages('snmp')

    # ulsfo, single phase PDUs
    facilities::monitor_pdu_1phase { 'ps1-22-ulsfo':
        ip    => '10.128.128.12',
        # PoPs don't have row diversity, using rack
        row   => '22',
        site  => 'ulsfo',
        model => 'sentry4',
    }
    facilities::monitor_pdu_1phase { 'ps1-23-ulsfo':
        ip    => '10.128.128.13',
        # PoPs don't have row diversity, using rack
        row   => '23',
        site  => 'ulsfo',
        model => 'sentry4',
    }

    # eqsin, single phase PDUs
    facilities::monitor_pdu_1phase { 'ps1-603-eqsin':
        ip    => '10.132.128.10',
        # PoPs don't have row diversity, using rack
        row   => '603',
        site  => 'eqsin',
        model => 'sentry4',
    }
    facilities::monitor_pdu_1phase { 'ps1-604-eqsin':
        ip    => '10.132.128.11',
        # PoPs don't have row diversity, using rack
        row   => '604',
        site  => 'eqsin',
        model => 'sentry4',
    }

    # esams, single phase PDUs
    facilities::monitor_pdu_1phase { 'ps1-oe14-esams':
        ip    => '10.21.0.16',
        # PoPs don't have row diversity, using rack
        row   => 'OE14',
        site  => 'esams',
        model => 'sentry4',
    }
    facilities::monitor_pdu_1phase { 'ps1-oe15-esams':
        ip    => '10.21.0.17',
        # PoPs don't have row diversity, using rack
        row   => 'OE15',
        site  => 'esams',
        model => 'sentry4',
    }
    facilities::monitor_pdu_1phase { 'ps1-oe16-esams':
        ip    => '10.21.0.18',
        # PoPs don't have row diversity, using rack
        row   => 'OE16',
        site  => 'esams',
        model => 'sentry4',
    }

    # drmrs, single phase PDUs
    facilities::monitor_pdu_1phase { 'ps1-b12-drmrs':
        ip    => '10.136.128.8',
        row   => '54',
        site  => 'drmrs',
        model => 'sentry4',
    }

    facilities::monitor_pdu_1phase { 'ps1-b13-drmrs':
        ip    => '10.136.128.9',
        row   => '54',
        site  => 'drmrs',
        model => 'sentry4',
    }

    # eqiad
    # A
    facilities::monitor_pdu_3phase { 'ps1-a1-eqiad':
        ip    => '10.65.0.32',
        row   => 'a',
        site  => 'eqiad',
        model => 'sentry4',
    }
    facilities::monitor_pdu_3phase { 'ps1-a2-eqiad':
        ip    => '10.65.0.33',
        row   => 'a',
        site  => 'eqiad',
        model => 'sentry4',
    }
    facilities::monitor_pdu_3phase { 'ps1-a3-eqiad':
        ip    => '10.65.0.34',
        row   => 'a',
        site  => 'eqiad',
        model => 'sentry4',
    }
    facilities::monitor_pdu_3phase { 'ps1-a4-eqiad':
        ip    => '10.65.0.35',
        row   => 'a',
        site  => 'eqiad',
        model => 'sentry4',
    }
    facilities::monitor_pdu_3phase { 'ps1-a5-eqiad':
        ip    => '10.65.0.36',
        row   => 'a',
        site  => 'eqiad',
        model => 'sentry4',
    }
    facilities::monitor_pdu_3phase { 'ps1-a6-eqiad':
        ip    => '10.65.0.37',
        row   => 'a',
        site  => 'eqiad',
        model => 'sentry4',
    }
    facilities::monitor_pdu_3phase { 'ps1-a7-eqiad':
        ip    => '10.65.0.38',
        row   => 'a',
        site  => 'eqiad',
        model => 'sentry4',
    }
    facilities::monitor_pdu_3phase { 'ps1-a8-eqiad':
        ip    => '10.65.0.39',
        row   => 'a',
        site  => 'eqiad',
        model => 'sentry4',
    }
    # B
    facilities::monitor_pdu_3phase { 'ps1-b1-eqiad':
        ip    => '10.65.0.40',
        row   => 'b',
        site  => 'eqiad',
        model => 'sentry4',
    }
    facilities::monitor_pdu_3phase { 'ps1-b2-eqiad':
        ip    => '10.65.0.41',
        row   => 'b',
        site  => 'eqiad',
        model => 'sentry4',
    }
    facilities::monitor_pdu_3phase { 'ps1-b3-eqiad':
        ip    => '10.65.0.42',
        row   => 'b',
        site  => 'eqiad',
        model => 'sentry4',
    }
    facilities::monitor_pdu_3phase { 'ps1-b4-eqiad':
        ip    => '10.65.0.43',
        row   => 'b',
        site  => 'eqiad',
        model => 'sentry4',
    }
    facilities::monitor_pdu_3phase { 'ps1-b5-eqiad':
        ip    => '10.65.0.44',
        row   => 'b',
        site  => 'eqiad',
        model => 'sentry4',
    }
    facilities::monitor_pdu_3phase { 'ps1-b6-eqiad':
        ip    => '10.65.0.45',
        row   => 'b',
        site  => 'eqiad',
        model => 'sentry4',
    }
    facilities::monitor_pdu_3phase { 'ps1-b7-eqiad':
        ip    => '10.65.0.46',
        row   => 'b',
        site  => 'eqiad',
        model => 'sentry4',
    }
    facilities::monitor_pdu_3phase { 'ps1-b8-eqiad':
        ip    => '10.65.0.47',
        row   => 'b',
        site  => 'eqiad',
        model => 'sentry4',
    }
    # C
    facilities::monitor_pdu_3phase { 'ps1-c1-eqiad':
        ip    => '10.65.0.48',
        row   => 'c',
        site  => 'eqiad',
        model => 'sentry4',
    }
    facilities::monitor_pdu_3phase { 'ps1-c2-eqiad':
        ip    => '10.65.0.49',
        row   => 'c',
        site  => 'eqiad',
        model => 'sentry4',
    }
    facilities::monitor_pdu_3phase { 'ps1-c3-eqiad':
        ip    => '10.65.0.50',
        row   => 'c',
        site  => 'eqiad',
        model => 'sentry4',
    }
    facilities::monitor_pdu_3phase { 'ps1-c4-eqiad':
        ip    => '10.65.0.51',
        row   => 'c',
        site  => 'eqiad',
        model => 'sentry4',
    }
    facilities::monitor_pdu_3phase { 'ps1-c5-eqiad':
        ip    => '10.65.0.52',
        row   => 'c',
        site  => 'eqiad',
        model => 'sentry4',
    }
    facilities::monitor_pdu_3phase { 'ps1-c6-eqiad':
        ip    => '10.65.0.53',
        row   => 'c',
        site  => 'eqiad',
        model => 'sentry4',
    }
    facilities::monitor_pdu_3phase { 'ps1-c7-eqiad':
        ip    => '10.65.0.54',
        row   => 'c',
        site  => 'eqiad',
        model => 'sentry4',
    }
    facilities::monitor_pdu_3phase { 'ps1-c8-eqiad':
        ip    => '10.65.0.55',
        row   => 'c',
        site  => 'eqiad',
        model => 'sentry4',
    }
    # D
    facilities::monitor_pdu_3phase { 'ps1-d1-eqiad':
        ip    => '10.65.0.56',
        row   => 'd',
        site  => 'eqiad',
        model => 'sentry4',
    }
    facilities::monitor_pdu_3phase { 'ps1-d2-eqiad':
        ip    => '10.65.0.57',
        row   => 'd',
        site  => 'eqiad',
        model => 'sentry4',
    }
    facilities::monitor_pdu_3phase { 'ps1-d3-eqiad':
        ip    => '10.65.0.58',
        row   => 'd',
        site  => 'eqiad',
        model => 'sentry4',
    }
    facilities::monitor_pdu_3phase { 'ps1-d4-eqiad':
        ip    => '10.65.0.59',
        row   => 'd',
        site  => 'eqiad',
        model => 'sentry4',
    }
    facilities::monitor_pdu_3phase { 'ps1-d5-eqiad':
        ip    => '10.65.0.60',
        row   => 'd',
        site  => 'eqiad',
        model => 'sentry4',
    }
    facilities::monitor_pdu_3phase { 'ps1-d6-eqiad':
        ip    => '10.65.0.61',
        row   => 'd',
        site  => 'eqiad',
        model => 'sentry4',
    }
    facilities::monitor_pdu_3phase { 'ps1-d7-eqiad':
        ip    => '10.65.0.62',
        row   => 'd',
        site  => 'eqiad',
        model => 'sentry4',
    }
    facilities::monitor_pdu_3phase { 'ps1-d8-eqiad':
        ip    => '10.65.0.63',
        row   => 'd',
        site  => 'eqiad',
        model => 'sentry4',
    }
    facilities::monitor_pdu_3phase { 'ps1-e1-eqiad':
        ip    => '10.65.2.45',
        row   => 'e',
        site  => 'eqiad',
        model => 'sentry4',
    }
    facilities::monitor_pdu_3phase { 'ps1-e2-eqiad':
        ip    => '10.65.2.46',
        row   => 'e',
        site  => 'eqiad',
        model => 'sentry4',
    }
    facilities::monitor_pdu_3phase { 'ps1-e3-eqiad':
        ip    => '10.65.2.47',
        row   => 'e',
        site  => 'eqiad',
        model => 'sentry4',
    }
    facilities::monitor_pdu_3phase { 'ps1-e4-eqiad':
        ip    => '10.65.2.48',
        row   => 'e',
        site  => 'eqiad',
        model => 'sentry4',
    }
    facilities::monitor_pdu_3phase { 'ps1-a1-codfw':
        ip    => '10.193.0.25',
        row   => 'a',
        site  => 'codfw',
        model => 'sentry4',
    }
    facilities::monitor_pdu_3phase { 'ps1-a2-codfw':
        ip    => '10.193.0.26',
        row   => 'a',
        site  => 'codfw',
        model => 'sentry4',
    }
    facilities::monitor_pdu_3phase { 'ps1-a3-codfw':
        ip    => '10.193.0.27',
        row   => 'a',
        site  => 'codfw',
        model => 'sentry4',
    }
    facilities::monitor_pdu_3phase { 'ps1-a4-codfw':
        ip    => '10.193.0.28',
        row   => 'a',
        site  => 'codfw',
        model => 'sentry4',
    }
    facilities::monitor_pdu_3phase { 'ps1-a5-codfw':
        ip    => '10.193.0.29',
        row   => 'a',
        site  => 'codfw',
        model => 'sentry4',
    }
    facilities::monitor_pdu_3phase { 'ps1-a6-codfw':
        ip    => '10.193.0.30',
        row   => 'a',
        site  => 'codfw',
        model => 'sentry4',
    }
    facilities::monitor_pdu_3phase { 'ps1-a7-codfw':
        ip    => '10.193.0.31',
        row   =>  'a',
        site  =>  'codfw',
        model => 'sentry4',
    }
    facilities::monitor_pdu_3phase { 'ps1-a8-codfw':
        ip   => '10.193.0.32',
        row  => 'a',
        site => 'codfw',
    }
    facilities::monitor_pdu_3phase { 'ps1-b1-codfw':
        ip    => '10.193.0.33',
        row   => 'b',
        site  => 'codfw',
        model => 'sentry4',
    }
    facilities::monitor_pdu_3phase { 'ps1-b2-codfw':
        ip    => '10.193.0.34',
        row   => 'b',
        site  => 'codfw',
        model => 'sentry4',
    }
    facilities::monitor_pdu_3phase { 'ps1-b3-codfw':
        ip    => '10.193.0.35',
        row   => 'b',
        site  => 'codfw',
        model => 'sentry4',
    }
    facilities::monitor_pdu_3phase { 'ps1-b4-codfw':
        ip    => '10.193.0.36',
        row   => 'b',
        site  => 'codfw',
        model => 'sentry4',
    }
    facilities::monitor_pdu_3phase { 'ps1-b5-codfw':
        ip    => '10.193.0.37',
        row   => 'b',
        site  => 'codfw',
        model => 'sentry4',
    }
    facilities::monitor_pdu_3phase { 'ps1-b6-codfw':
        ip    => '10.193.0.38',
        row   => 'b',
        site  => 'codfw',
        model => 'sentry4',
    }
    facilities::monitor_pdu_3phase { 'ps1-b7-codfw':
        ip    => '10.193.0.39',
        row   => 'b',
        site  => 'codfw',
        model => 'sentry4',
    }
    facilities::monitor_pdu_3phase { 'ps1-b8-codfw':
        ip    => '10.193.0.40',
        row   => 'b',
        site  => 'codfw',
        model => 'sentry4',
    }
    facilities::monitor_pdu_3phase { 'ps1-c1-codfw':
        ip    => '10.193.0.41',
        row   => 'c',
        site  => 'codfw',
        model => 'sentry4',
    }
    facilities::monitor_pdu_3phase { 'ps1-c2-codfw':
        ip    => '10.193.0.42',
        row   => 'c',
        site  => 'codfw',
        model => 'sentry4',
    }
    facilities::monitor_pdu_3phase { 'ps1-c3-codfw':
        ip    => '10.193.0.43',
        row   => 'c',
        site  => 'codfw',
        model => 'sentry4',
    }
    facilities::monitor_pdu_3phase { 'ps1-c4-codfw':
        ip    => '10.193.0.44',
        row   => 'c',
        site  => 'codfw',
        model => 'sentry4',
    }
    facilities::monitor_pdu_3phase { 'ps1-c5-codfw':
        ip    => '10.193.0.45',
        row   => 'c',
        site  => 'codfw',
        model => 'sentry4',
    }
    facilities::monitor_pdu_3phase { 'ps1-c6-codfw':
        ip    => '10.193.0.46',
        row   => 'c',
        site  => 'codfw',
        model => 'sentry4',
    }
    facilities::monitor_pdu_3phase { 'ps1-c7-codfw':
        ip    => '10.193.0.47',
        row   => 'c',
        site  => 'codfw',
        model => 'sentry4',
    }
    facilities::monitor_pdu_3phase { 'ps1-c8-codfw':
        ip   => '10.193.0.48',
        row  => 'c',
        site => 'codfw',
    }
    facilities::monitor_pdu_3phase { 'ps1-d1-codfw':
        ip    => '10.193.0.49',
        row   => 'd',
        site  => 'codfw',
        model => 'sentry4',
    }
    facilities::monitor_pdu_3phase { 'ps1-d2-codfw':
        ip    => '10.193.0.50',
        row   => 'd',
        site  => 'codfw',
        model => 'sentry4',
    }
    facilities::monitor_pdu_3phase { 'ps1-d3-codfw':
        ip   => '10.193.0.51',
        row  => 'd',
        site => 'codfw',
    }
    facilities::monitor_pdu_3phase { 'ps1-d4-codfw':
        ip   => '10.193.0.52',
        row  => 'd',
        site => 'codfw',
    }
    facilities::monitor_pdu_3phase { 'ps1-d5-codfw':
        ip   => '10.193.0.53',
        row  => 'd',
        site => 'codfw',
    }
    facilities::monitor_pdu_3phase { 'ps1-d6-codfw':
        ip   => '10.193.0.54',
        row  => 'd',
        site => 'codfw',
    }
    facilities::monitor_pdu_3phase { 'ps1-d7-codfw':
        ip   => '10.193.0.55',
        row  => 'd',
        site => 'codfw',
    }
    facilities::monitor_pdu_3phase { 'ps1-d8-codfw':
        ip   => '10.193.0.56',
        row  => 'd',
        site => 'codfw',
    }

}
