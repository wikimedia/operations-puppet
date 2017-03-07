# monitoring of non-server data center
# hardware like power distribution units and cameras
class facilities {

    # The PDUs are queried over SNMP using the snmp command provided by the snmp
    # package. For now ensure it here but it may need to be put in another place
    # in the future
    package { 'snmp':
        ensure => installed,
    }

    # eqiad
    # A
    facilities::monitor_pdu_3phase { 'ps1-a1-eqiad':
        ip   => '10.65.0.32',
        row  => 'a',
        site => 'eqiad',
    }
    facilities::monitor_pdu_3phase { 'ps1-a2-eqiad':
        ip   => '10.65.0.33',
        row  => 'a',
        site => 'eqiad',
    }
    facilities::monitor_pdu_3phase { 'ps1-a3-eqiad':
        ip   => '10.65.0.34',
        row  => 'a',
        site => 'eqiad',
    }
    facilities::monitor_pdu_3phase { 'ps1-a4-eqiad':
        ip   => '10.65.0.35',
        row  => 'a',
        site => 'eqiad',
    }
    facilities::monitor_pdu_3phase { 'ps1-a5-eqiad':
        ip   => '10.65.0.36',
        row  => 'a',
        site => 'eqiad',
    }
    facilities::monitor_pdu_3phase { 'ps1-a6-eqiad':
        ip   => '10.65.0.37',
        row  => 'a',
        site => 'eqiad',
    }
    facilities::monitor_pdu_3phase { 'ps1-a7-eqiad':
        ip   => '10.65.0.38',
        row  => 'a',
        site => 'eqiad',
    }
    facilities::monitor_pdu_3phase { 'ps1-a8-eqiad':
        ip   => '10.65.0.39',
        row  => 'a',
        site => 'eqiad',
    }
    # B
    facilities::monitor_pdu_3phase { 'ps1-b1-eqiad':
        ip   => '10.65.0.40',
        row  => 'b',
        site => 'eqiad',
    }
    facilities::monitor_pdu_3phase { 'ps1-b2-eqiad':
        ip   => '10.65.0.41',
        row  => 'b',
        site => 'eqiad',
    }
    facilities::monitor_pdu_3phase { 'ps1-b3-eqiad':
        ip   => '10.65.0.42',
        row  => 'b',
        site => 'eqiad',
    }
    facilities::monitor_pdu_3phase { 'ps1-b4-eqiad':
        ip   => '10.65.0.43',
        row  => 'b',
        site => 'eqiad',
    }
    facilities::monitor_pdu_3phase { 'ps1-b5-eqiad':
        ip   => '10.65.0.44',
        row  => 'b',
        site => 'eqiad',
    }
    facilities::monitor_pdu_3phase { 'ps1-b6-eqiad':
        ip   => '10.65.0.45',
        row  => 'b',
        site => 'eqiad',
    }
    facilities::monitor_pdu_3phase { 'ps1-b7-eqiad':
        ip   => '10.65.0.46',
        row  => 'b',
        site => 'eqiad',
    }
    facilities::monitor_pdu_3phase { 'ps1-b8-eqiad':
        ip   => '10.65.0.47',
        row  => 'b',
        site => 'eqiad',
    }
    # C
    facilities::monitor_pdu_3phase { 'ps1-c1-eqiad':
        ip   => '10.65.0.48',
        row  => 'c',
        site => 'eqiad',
    }
    facilities::monitor_pdu_3phase { 'ps1-c2-eqiad':
        ip   => '10.65.0.49',
        row  => 'c',
        site => 'eqiad',
    }
    facilities::monitor_pdu_3phase { 'ps1-c3-eqiad':
        ip   => '10.65.0.50',
        row  => 'c',
        site => 'eqiad',
    }
    facilities::monitor_pdu_3phase { 'ps1-c4-eqiad':
        ip   => '10.65.0.51',
        row  => 'c',
        site => 'eqiad',
    }
    facilities::monitor_pdu_3phase { 'ps1-c5-eqiad':
        ip   => '10.65.0.52',
        row  => 'c',
        site => 'eqiad',
    }
    facilities::monitor_pdu_3phase { 'ps1-c6-eqiad':
        ip   => '10.65.0.53',
        row  => 'c',
        site => 'eqiad',
    }
    facilities::monitor_pdu_3phase { 'ps1-c7-eqiad':
        ip   => '10.65.0.54',
        row  => 'c',
        site => 'eqiad',
    }
    facilities::monitor_pdu_3phase { 'ps1-c8-eqiad':
        ip   => '10.65.0.55',
        row  => 'c',
        site => 'eqiad',
    }
    # D
    facilities::monitor_pdu_3phase { 'ps1-d1-eqiad':
        ip   => '10.65.0.56',
        row  => 'd',
        site => 'eqiad',
    }
    facilities::monitor_pdu_3phase { 'ps1-d2-eqiad':
        ip   => '10.65.0.57',
        row  => 'd',
        site => 'eqiad',
    }
    facilities::monitor_pdu_3phase { 'ps1-d3-eqiad':
        ip   => '10.65.0.58',
        row  => 'd',
        site => 'eqiad',
    }
    facilities::monitor_pdu_3phase { 'ps1-d4-eqiad':
        ip   => '10.65.0.59',
        row  => 'd',
        site => 'eqiad',
    }
    facilities::monitor_pdu_3phase { 'ps1-d5-eqiad':
        ip   => '10.65.0.60',
        row  => 'd',
        site => 'eqiad',
    }
    facilities::monitor_pdu_3phase { 'ps1-d6-eqiad':
        ip   => '10.65.0.61',
        row  => 'd',
        site => 'eqiad',
    }
    facilities::monitor_pdu_3phase { 'ps1-d7-eqiad':
        ip   => '10.65.0.62',
        row  => 'd',
        site => 'eqiad',
    }
    facilities::monitor_pdu_3phase { 'ps1-d8-eqiad':
        ip   => '10.65.0.63',
        row  => 'd',
        site => 'eqiad',
    }
}
