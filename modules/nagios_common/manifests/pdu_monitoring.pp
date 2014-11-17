class nagios_common::pdu_monitoring {

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
    nagios_common::monitor_pdu_3phase { 'ps1-a1-eqiad':
        ip => '10.65.0.32',
    }
    nagios_common::monitor_pdu_3phase { 'ps1-a2-eqiad':
        ip => '10.65.0.33',
    }
    nagios_common::monitor_pdu_3phase { 'ps1-a3-eqiad':
        ip => '10.65.0.34',
    }
    nagios_common::monitor_pdu_3phase { 'ps1-a4-eqiad':
        ip => '10.65.0.35',
    }
    nagios_common::monitor_pdu_3phase { 'ps1-a5-eqiad':
        ip => '10.65.0.36',
    }
    nagios_common::monitor_pdu_3phase { 'ps1-a6-eqiad':
        ip => '10.65.0.37',
    }
    nagios_common::monitor_pdu_3phase { 'ps1-a7-eqiad':
        ip => '10.65.0.38',
    }
    nagios_common::monitor_pdu_3phase { 'ps1-a8-eqiad':
        ip => '10.65.0.39',
    }
    # B
    nagios_common::monitor_pdu_3phase { 'ps1-b1-eqiad':
        ip => '10.65.0.40',
    }
    nagios_common::monitor_pdu_3phase { 'ps1-b2-eqiad':
        ip => '10.65.0.41',
    }
    nagios_common::monitor_pdu_3phase { 'ps1-b3-eqiad':
        ip => '10.65.0.42',
    }
    nagios_common::monitor_pdu_3phase { 'ps1-b4-eqiad':
        ip => '10.65.0.43',
    }
    nagios_common::monitor_pdu_3phase { 'ps1-b5-eqiad':
        ip => '10.65.0.44',
    }
    nagios_common::monitor_pdu_3phase { 'ps1-b6-eqiad':
        ip => '10.65.0.45',
    }
    nagios_common::monitor_pdu_3phase { 'ps1-b7-eqiad':
        ip => '10.65.0.46',
    }
    nagios_common::monitor_pdu_3phase { 'ps1-b8-eqiad':
        ip => '10.65.0.47',
    }
    # C
    nagios_common::monitor_pdu_3phase { 'ps1-c1-eqiad':
        ip => '10.65.0.48',
    }
    nagios_common::monitor_pdu_3phase { 'ps1-c2-eqiad':
        ip => '10.65.0.49',
    }
    nagios_common::monitor_pdu_3phase { 'ps1-c3-eqiad':
        ip => '10.65.0.50',
    }
    nagios_common::monitor_pdu_3phase { 'ps1-c4-eqiad':
        ip => '10.65.0.51',
    }
    nagios_common::monitor_pdu_3phase { 'ps1-c5-eqiad':
        ip => '10.65.0.52',
    }
    nagios_common::monitor_pdu_3phase { 'ps1-c6-eqiad':
        ip => '10.65.0.53',
    }
    nagios_common::monitor_pdu_3phase { 'ps1-c7-eqiad':
        ip => '10.65.0.54',
    }
    nagios_common::monitor_pdu_3phase { 'ps1-c8-eqiad':
        ip => '10.65.0.55',
    }
}

