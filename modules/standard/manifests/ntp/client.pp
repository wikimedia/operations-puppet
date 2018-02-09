# == Class standard::ntp::client
#
# Class most servers must include
class standard::ntp::client () {
    require standard::ntp

    $wmf_peers = $::standard::ntp::wmf_peers
    # This maps the servers that regular clients use
    $client_upstreams = {
        eqiad => array_concat($wmf_peers['eqiad'], $wmf_peers['codfw']),
        codfw => array_concat($wmf_peers['eqiad'], $wmf_peers['codfw']),
        esams => array_concat($wmf_peers['esams'], $wmf_peers['eqiad']),
        ulsfo => array_concat($wmf_peers['ulsfo'], $wmf_peers['codfw']),
        eqsin => array_concat($wmf_peers['eqsin'], $wmf_peers['codfw']),
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
    }

}
