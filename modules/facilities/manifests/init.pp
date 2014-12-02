class facilities {

    @monitoring::group { 'pdus':
        description => 'PDUs',
    }

    # The PDUs are queried over SNMP using the snmp command provided by the snmp
    # package. For now ensure it here but it may need to be put in another place
    # in the future
    package { 'snmp':
        ensure => installed,
    }
    # eqiad
    # A
    monitor_pdu_3phase { 'ps1-a1-eqiad':
        ip => '10.65.0.32',
    }
    monitor_pdu_3phase { 'ps1-a2-eqiad':
        ip => '10.65.0.33',
    }
    monitor_pdu_3phase { 'ps1-a3-eqiad':
        ip => '10.65.0.34',
    }
    monitor_pdu_3phase { 'ps1-a4-eqiad':
        ip => '10.65.0.35',
    }
    monitor_pdu_3phase { 'ps1-a5-eqiad':
        ip => '10.65.0.36',
    }
    monitor_pdu_3phase { 'ps1-a6-eqiad':
        ip => '10.65.0.37',
    }
    monitor_pdu_3phase { 'ps1-a7-eqiad':
        ip => '10.65.0.38',
    }
    monitor_pdu_3phase { 'ps1-a8-eqiad':
        ip => '10.65.0.39',
    }
    # B
    monitor_pdu_3phase { 'ps1-b1-eqiad':
        ip => '10.65.0.40',
    }
    monitor_pdu_3phase { 'ps1-b2-eqiad':
        ip => '10.65.0.41',
    }
    monitor_pdu_3phase { 'ps1-b3-eqiad':
        ip => '10.65.0.42',
    }
    monitor_pdu_3phase { 'ps1-b4-eqiad':
        ip => '10.65.0.43',
    }
    monitor_pdu_3phase { 'ps1-b5-eqiad':
        ip => '10.65.0.44',
    }
    monitor_pdu_3phase { 'ps1-b6-eqiad':
        ip => '10.65.0.45',
    }
    monitor_pdu_3phase { 'ps1-b7-eqiad':
        ip => '10.65.0.46',
    }
    monitor_pdu_3phase { 'ps1-b8-eqiad':
        ip => '10.65.0.47',
    }
    # C
    monitor_pdu_3phase { 'ps1-c1-eqiad':
        ip => '10.65.0.48',
    }
    monitor_pdu_3phase { 'ps1-c2-eqiad':
        ip => '10.65.0.49',
    }
    monitor_pdu_3phase { 'ps1-c3-eqiad':
        ip => '10.65.0.50',
    }
    monitor_pdu_3phase { 'ps1-c4-eqiad':
        ip => '10.65.0.51',
    }
    monitor_pdu_3phase { 'ps1-c5-eqiad':
        ip => '10.65.0.52',
    }
    monitor_pdu_3phase { 'ps1-c6-eqiad':
        ip => '10.65.0.53',
    }
    monitor_pdu_3phase { 'ps1-c7-eqiad':
        ip => '10.65.0.54',
    }
    monitor_pdu_3phase { 'ps1-c8-eqiad':
        ip => '10.65.0.55',
    }
}

