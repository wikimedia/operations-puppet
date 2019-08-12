# Placeholder define for single phase PDUs monitoring
# Also used to generate Prometheus targets/configuration

# See also https://phabricator.wikimedia.org/T229101
# and https://phabricator.wikimedia.org/T148541
define facilities::monitor_pdu_1phase(
    Stdlib::Ip_address $ip,
    String $row,
    String $site,
    Integer $breaker = 30,
    Boolean $redundant = true,
    String $model = 'sentry3',
) {
    @monitoring::host { $title:
        ip_address => $ip,
        group      => 'pdus',
    }
}
