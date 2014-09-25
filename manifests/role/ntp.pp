class role::ntp {
    # These are our servers - they all peer to each other
    #   and sync to upstream NTP pool servers.
    $wmf_peers = {
        eqiad => [
            'chromium.wikimedia.org',     # eqiad recdns
            'hydrogen.wikimedia.org',     # eqiad recdns
        ],
        codfw => [
            'acamar.wikimedia.org',       # codfw recdns
            'achernar.wikimedia.org',     # codfw recdns
        ],
        esams => [
            'nescio.esams.wikimedia.org', # esams recdns
        ],
        ulsfo => [],
        pmtpa => [],
    }

    # Combines the peers above into a single list
    $wmf_all_peers = array_concat(
        $wmf_peers['eqiad'],
        $wmf_peers['codfw'],
        $wmf_peers['esams'],
        $wmf_peers['ulsfo'],
        $wmf_peers['pmtpa']
    )

    # These are the pool servers used by the peers above
    $peer_upstreams = {
        eqiad => [
            '0.us.pool.ntp.org',
            '1.us.pool.ntp.org',
            '2.us.pool.ntp.org',
            '3.us.pool.ntp.org',
        ],
        codfw => [
            '0.us.pool.ntp.org',
            '1.us.pool.ntp.org',
            '2.us.pool.ntp.org',
            '3.us.pool.ntp.org',
        ],
        esams => [
            '0.europe.pool.ntp.org',
            '1.europe.pool.ntp.org',
            '2.europe.pool.ntp.org',
            '3.europe.pool.ntp.org',
        ],
        ulsfo => [],
        pmtpa => [],
    }

    # This maps the servers that regular clients use
    $client_upstreams = {
        eqiad => array_concat($wmf_peers['eqiad'], $wmf_peers['codfw']),
        codfw => array_concat($wmf_peers['eqiad'], $wmf_peers['codfw']),
        esams => array_concat($wmf_peers['esams'], $wmf_peers['eqiad']),
        ulsfo => array_concat($wmf_peers['eqiad'], $wmf_peers['codfw']),
        pmtpa => array_concat($wmf_peers['eqiad'], $wmf_peers['codfw']),
    }

    # TODO: generate from $network::constants::all_networks
    $our_networks_acl = [
        '10.0.0.0 mask 255.0.0.0',
        '208.80.152.0 mask 255.255.252.0',
        '91.198.174.0 mask 255.255.255.0',
        '198.35.26.0 mask 255.255.254.0',
        '185.15.56.0 mask 255.255.252.0',
        '2620:0:860:: mask ffff:ffff:fffc::',
        '2a02:ec80:: mask ffff:ffff::',
    ]

    # neon for ntp monitoring queries
    $neon_acl = [
        '208.80.154.14 mask 255.255.255.255',
    ]

    if $::fqdn in $wmf_all_peers { # peer config
        system::role { 'ntp': description => 'NTP server' }

        ntp::daemon { 'server':
            servers => $peer_upstreams[$::site],
            peers => delete($wmf_all_peers, $::fqdn),
            time_acl => $our_networks_acl,
            query_acl => $neon_acl,
        }

        monitor_service { 'ntp peers':
            description   => 'NTP peers',
            check_command => 'check_ntp_peer!0.1!0.5';
        }
    }
    else { # client config
        ntp::daemon { 'client':
            servers => $client_upstreams[$::site],
            query_acl => $neon_acl,
        }

        monitor_service { 'ntp':
            description   => 'NTP',
            check_command => 'check_ntp_time!0.5!1',
            retries       => 15, # wait for resync, don't flap after restart
        }
    }
}
