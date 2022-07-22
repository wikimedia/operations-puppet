# SPDX-License-Identifier: Apache-2.0
define facilities::monitor_pdu_3phase(
    Stdlib::IP::Address  $ip,
    String               $row,
    String               $site,
    Integer              $breaker      = 30,
    Boolean              $redundant    = true,
    String               $model        = 'sentry3',
    Hash[String, String] $mgmt_parents = {}
) {
    include facilities
    $_mgmt_parents = pick($mgmt_parents, $facilities::mgmt_parents)

    @monitoring::host { $title:
        ip_address => $ip,
        group      => 'pdus',
        parents    => $_mgmt_parents[$site],
    }

    facilities::monitor_pdu_service { "${title}-infeed-load-tower-A-phase-X":
        host      => $title,
        ip        => $ip,
        row       => $row,
        site      => $site,
        tower     => '1',
        infeed    => '1',
        breaker   => $breaker,
        redundant => $redundant,
        model     => $model,
    }

    facilities::monitor_pdu_service { "${title}-infeed-load-tower-A-phase-Y":
        host      => $title,
        ip        => $ip,
        row       => $row,
        site      => $site,
        tower     => '1',
        infeed    => '2',
        breaker   => $breaker,
        redundant => $redundant,
        model     => $model,
    }
    facilities::monitor_pdu_service { "${title}-infeed-load-tower-A-phase-Z":
        host      => $title,
        ip        => $ip,
        row       => $row,
        site      => $site,
        tower     => '1',
        infeed    => '3',
        breaker   => $breaker,
        redundant => $redundant,
        model     => $model,
    }

    if $redundant == true {
        facilities::monitor_pdu_service { "${title}-infeed-load-tower-B-phase-X":
            host      => $title,
            ip        => $ip,
            row       => $row,
            site      => $site,
            tower     => '2',
            infeed    => '1',
            breaker   => $breaker,
            redundant => $redundant,
            model     => $model,
        }
        facilities::monitor_pdu_service { "${title}-infeed-load-tower-B-phase-Y":
            host      => $title,
            ip        => $ip,
            row       => $row,
            site      => $site,
            tower     => '2',
            infeed    => '2',
            breaker   => $breaker,
            redundant => $redundant,
            model     => $model,
        }
        facilities::monitor_pdu_service { "${title}-infeed-load-tower-B-phase-Z":
            host      => $title,
            ip        => $ip,
            row       => $row,
            site      => $site,
            tower     => '2',
            infeed    => '3',
            breaker   => $breaker,
            redundant => $redundant,
            model     => $model,
        }
    }
}
