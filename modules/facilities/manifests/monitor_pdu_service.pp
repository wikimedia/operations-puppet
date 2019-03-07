# definition for monitoring PDUs via SNMP
# T79062
# TODO: Monitor infeed status
define facilities::monitor_pdu_service(
    $host,
    $ip,
    $row,
    $site,
    $tower,
    $infeed,
    $breaker  = '30',
    $redundant= true
) {

    include ::passwords::network

    $servertech_tree = '.1.3.6.1.4.1.1718'
    $infeedload      = '.3.2.2.1.7'
    $oid = "${servertech_tree}${infeedload}.${tower}.${infeed}"

    # The value of infeedloadValue is given in _hundredths of Amps_,
    # thats why we multiply here

    if $redundant == false {
        $warn_hi = $breaker * 0.8 * 100
        $crit_hi = $breaker * 0.85 * 100
    } else {
        $warn_hi = $breaker * 0.4 * 100
        $crit_hi = $breaker * 0.8 * 100
    }

    $snmp_community = $site ? {
        'codfw' => $passwords::network::snmp_ro_community_pdus_codfw,
        default => $passwords::network::snmp_ro_community,
    }

    @monitoring::service { $title:
        host          => $host,
        group         => 'pdus',
        description   => $title,
        check_command => "check_snmp_generic!${snmp_community}!${oid}!${title}!${warn_hi}!${crit_hi}",
        notes_url     => 'https://wikitech.wikimedia.org/wiki/Dc-operations/Hardware_Troubleshooting_Runbook',
    }

}

