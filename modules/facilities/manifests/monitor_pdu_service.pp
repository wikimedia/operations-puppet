# SPDX-License-Identifier: Apache-2.0
# definition for monitoring PDUs via SNMP
# T79062
# TODO: Monitor infeed status
define facilities::monitor_pdu_service(
    # Interestingly, not FQDN, not even valid hostname
    Stdlib::Host $host,
    Stdlib::IP::Address $ip,
    String $row,
    String $site,
    String $tower,
    String $infeed,
    Integer $breaker  = 30,
    Boolean $redundant = true,
    String $model = 'sentry3',
) {

    include ::passwords::network

    case $model {
        'sentry3': {
            $servertech_tree = '.1.3.6.1.4.1.1718'
            $infeedload      = '.3.2.2.1.7'
            $oid = "${servertech_tree}${infeedload}.${tower}.${infeed}"
        }
        'sentry4': {
            # Sentry4 -> Sentry3 MIB names conversion:
            # * unit       => tower
            # * input cord => N/A, fixed to '1'
            # * phase      => infeed

            $servertech_tree = '.1.3.6.1.4.1.1718'
            $infeedload      = '.4.1.5.3.1.6' # st4PhaseCurrent

            # Index: st4UnitIndex, st4InputCordIndex, st4PhaseIndex
            $oid = "${servertech_tree}${infeedload}.${tower}.1.${infeed}"
        }
        default: { fail("Unknown model ${model}") }
    }


    # The value of phase current is given in _hundredths of Amps_,
    # thats why we multiply here

    if $redundant == false {
        $warn_hi = $breaker * 0.8 * 100
        $crit_hi = $breaker * 0.85 * 100
    } else {
        $warn_hi = $breaker * 0.4 * 100
        $crit_hi = $breaker * 0.8 * 100
    }

    $snmp_community =  $passwords::network::snmp_ro_community

    @monitoring::service { $title:
        host          => $host,
        group         => 'pdus',
        description   => $title,
        check_command => "check_snmp_generic!${snmp_community}!${oid}!${title}!${warn_hi}!${crit_hi}",
        notes_url     => 'https://wikitech.wikimedia.org/wiki/Dc-operations/Hardware_Troubleshooting_Runbook',
    }

}
