define facilities::monitor_pdu_3phase(
    $ip,
    $row,
    $site,
    $breaker  = '30',
    $redundant= true
) {
    @monitoring::host { $title:
        ip_address => $ip,
        group      => 'pdus',
    }

    facilities::monitor_pdu_service { "${title}-infeed-load-tower-A-phase-X":
        host      => $title,
        ip        => $ip,
        tower     => '1',
        infeed    => '1',
        breaker   => $breaker,
        redundant => $redundant,
    }

    facilities::monitor_pdu_service { "${title}-infeed-load-tower-A-phase-Y":
        host      => $title,
        ip        => $ip,
        tower     => '1',
        infeed    => '2',
        breaker   => $breaker,
        redundant => $redundant,
    }
    facilities::monitor_pdu_service { "${title}-infeed-load-tower-A-phase-Z":
        host      => $title,
        ip        => $ip,
        tower     => '1',
        infeed    => '3',
        breaker   => $breaker,
        redundant => $redundant,
    }

    if $redundant == true {
        facilities::monitor_pdu_service { "${title}-infeed-load-tower-B-phase-X":
            host      => $title,
            ip        => $ip,
            tower     => '2',
            infeed    => '1',
            breaker   => $breaker,
            redundant => $redundant,
        }
        facilities::monitor_pdu_service { "${title}-infeed-load-tower-B-phase-Y":
            host      => $title,
            ip        => $ip,
            tower     => '2',
            infeed    => '2',
            breaker   => $breaker,
            redundant => $redundant,
        }
        facilities::monitor_pdu_service { "${title}-infeed-load-tower-B-phase-Z":
            host      => $title,
            ip        => $ip,
            tower     => '2',
            infeed    => '3',
            breaker   => $breaker,
            redundant => $redundant,
        }
    }
}

