# == Class standard::ntp::client
#
# Class most servers must include
class standard::ntp::client () {
    require standard::ntp

    # This maps the servers that regular clients use
    $client_upstreams = {
        eqiad => array_concat($::ntp_peers['eqiad'], $::ntp_peers['codfw']),
        codfw => array_concat($::ntp_peers['eqiad'], $::ntp_peers['codfw']),
        esams => array_concat($::ntp_peers['esams'], $::ntp_peers['eqiad']),
        ulsfo => array_concat($::ntp_peers['ulsfo'], $::ntp_peers['codfw']),
        eqsin => array_concat($::ntp_peers['eqsin'], $::ntp_peers['codfw']),
    }

    ntp::daemon { 'client':
        servers   => $client_upstreams[$::site],
        query_acl => $::standard::ntp::monitoring_acl,
    }

    monitoring::service { 'ntp':
        description    => 'NTP',
        check_command  => 'check_ntp_time!0.5!1',
        check_interval => 30,
        retry_interval => 15,
        notes_url      => 'https://wikitech.wikimedia.org/wiki/NTP',
    }

}
