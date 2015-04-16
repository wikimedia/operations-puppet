# definition for monitoring PDUs via SNMP
# T79062
# TODO: Monitor infeed status
define facilities::monitor_pdu_service(
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

    @monitoring::service { $title:
        host          => $host,
        group         => 'pdus',
        description   => $title,
        check_command => "check_snmp_generic!${passwords::nagios::snmp::pdu_snmp_pass}!${oid}!${title}!${warn_hi}!${crit_hi}",
    }

}

