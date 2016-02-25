# == Class standard::ntp::client
#
# Class most servers must include
class standard::ntp::client () {
    require standard::ntp
    # XXX special case for now, virt100x seem to need v4-only access
    #  (probably router/firewall issue needs to be tracked down)
    if $::hostname =~ /^virt[0-9]+$/ {
        $s_opt = '-4'
    }
    else {
        $s_opt = ''
    }

    $wmf_peers = $::standard::ntp::wmf_peers
    # This maps the servers that regular clients use
    $client_upstreams = {
        eqiad => array_concat($wmf_peers['eqiad'], $wmf_peers['codfw']),
        codfw => array_concat($wmf_peers['eqiad'], $wmf_peers['codfw']),
        esams => array_concat($wmf_peers['esams'], $wmf_peers['eqiad']),
        ulsfo => array_concat($wmf_peers['eqiad'], $wmf_peers['codfw']),
    }


    ntp::daemon { 'client':
        servers     => $client_upstreams[$::site],
        query_acl   => $::standard::ntp::neon_acl,
        servers_opt => $s_opt,
    }

    monitoring::service { 'ntp':
        description   => 'NTP',
        check_command => 'check_ntp_time!0.5!1',
        retries       => 20, # wait for resync, don't flap after restart
    }

}
