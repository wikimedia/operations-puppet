# facilities.pp

# definition for monitoring PDUs via SNMP
# RT #308

# TODO: Monitor infeed status

define monitor_pdu_service(
    $host,
    $ip,
    $tower,
    $infeed,
    $breaker  = '30',
    $redundant= true
) {

    include passwords::nagios::snmp

    $servertech_tree = '.1.3.6.1.4.1.1718'
    $infeedLoad      = '.3.2.2.1.7'
    $oid = "${servertech_tree}${infeedLoad}.${tower}.${infeed}"

    # The value of infeedLoadValue is given in _hundredths of Amps_,
    # thats why we multiply here

    if $redundant == false {
        $warn_hi = $breaker * 0.8 * 100
        $crit_hi = $breaker * 0.85 * 100
    } else {
        $warn_hi = $breaker * 0.4 * 100
        $crit_hi = $breaker * 0.8 * 100
    }

    @monitor_service { $title:
        host          => $host,
        group         => 'pdus',
        description   => $title,
        check_command => "check_snmp_generic!${passwords::nagios::snmp::pdu_snmp_pass}!${oid}!${title}!${warn_hi}!${crit_hi}",
    }

}

define monitor_pdu_3phase(
    $ip,
    $breaker  = '30',
    $redundant= true
) {
    @monitor_host { $title:
        ip_address => $ip,
        group      => 'pdus',
    }

    monitor_pdu_service { "${title}-infeed-load-tower-A-phase-X":
        host      => $title,
        ip        => $ip,
        tower     => '1',
        infeed    => '1',
        breaker   => $breaker,
        redundant => $redundant,
    }

    monitor_pdu_service { "${title}-infeed-load-tower-A-phase-Y":
        host      => $title,
        ip        => $ip,
        tower     => '1',
        infeed    => '2',
        breaker   => $breaker,
        redundant => $redundant,
    }
    monitor_pdu_service { "${title}-infeed-load-tower-A-phase-Z":
        host      => $title,
        ip        => $ip,
        tower     => '1',
        infeed    => '3',
        breaker   => $breaker,
        redundant => $redundant,
    }

    if $redundant == true {
        monitor_pdu_service { "${title}-infeed-load-tower-B-phase-X":
            host      => $title,
            ip        => $ip,
            tower     => '2',
            infeed    => '1',
            breaker   => $breaker,
            redundant => $redundant,
        }
        monitor_pdu_service { "${title}-infeed-load-tower-B-phase-Y":
            host      => $title,
            ip        => $ip,
            tower     => '2',
            infeed    => '2',
            breaker   => $breaker,
            redundant => $redundant,
        }
        monitor_pdu_service { "${title}-infeed-load-tower-B-phase-Z":
            host      => $title,
            ip        => $ip,
            tower     => '2',
            infeed    => '3',
            breaker   => $breaker,
            redundant => $redundant,
        }
    }
}

# Nagios monitoring
@monitor_group { 'pdus':
    description => 'PDUs',
    }


class facilities::pdu_monitoring {

    # The PDUs are queried over SNMP using the snmp command provided by the snmp
    # package. For now ensure it here but it may need to be put in another place
    # in the future
    package { 'snmp':
        ensure => installed,
    }
    # pmtpa
    # C
    monitor_pdu_3phase { 'ps1-c1-pmtpa':
        ip=> '10.1.5.20',
    }
    monitor_pdu_3phase { 'ps1-c2-pmtpa':
        ip=> '10.1.5.21',
    }
    monitor_pdu_3phase { 'ps1-c3-pmtpa':
        ip=> '10.1.5.22',
    }
    # D
    monitor_pdu_3phase { 'ps1-d1-pmtpa':
        ip=> '10.1.5.17',
    }
    monitor_pdu_3phase { 'ps1-d2-pmtpa':
        ip=> '10.1.5.18',
    }
    monitor_pdu_3phase { 'ps1-d3-pmtpa':
        ip=> '10.1.5.19',
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


class facilities::dc-cam-transcoder {
    system::role { 'misc::dc-cam-transcoder':
        description => 'Data center camera transcoder',
    }

    group { 'video':
        ensure => present,
        name   => 'video',
        system => true,
    }

    user { 'video':
        home       => '/var/lib/video',
        managehome => true,
        system     => true,
    }

    package { 'vlc-nox':
        ensure => 'latest',
    }
}
