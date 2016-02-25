class standard::ntp {
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
            'nescio.wikimedia.org',       # esams recdns
            'maerlant.wikimedia.org',     # esams recdns
        ],
        ulsfo => [],
    }

    # Combines the peers above into a single list
    $wmf_all_peers = array_concat(
        $wmf_peers['eqiad'],
        $wmf_peers['codfw'],
        $wmf_peers['esams'],
        $wmf_peers['ulsfo']
    )

    # NOTE to the future: we *should* be using regional
    #   NTP pool aliases, removing the per-server "restrict"
    #   lines in the config template, and adding a
    #   "restrict source ..." line, but current stable
    #   versions of ntpd do not yet support "restrict source"
    # The current sets of peers have some thought and research
    #   behind them based on current S2 lists (Sept 2014), but
    #   they will need long-term periodic upkeep until we can
    #   switch to per-site pool addrs + "restrict source"
    # These are the pool servers used by the peers above
    $peer_upstreams = {
        'chromium.wikimedia.org' => [
            'ac-ntp1.net.cmu.edu',
            'tock.teljet.net',
            'e.time.steadfast.net',
            '50.116.55.65',
        ],
        'hydrogen.wikimedia.org' => [
            'ac-ntp2.net.cmu.edu',
            'tick.teljet.net',
            'f.time.steadfast.net',
            'ntp3.servman.ca',
        ],
        'acamar.wikimedia.org' => [
            'ntp3.tamu.edu',
            'stratum2.ord2.publicntp.net',
            '72.14.183.239',
            'jikan.ae7.st',
        ],
        'achernar.wikimedia.org' => [
            'ntp3.tamu.edu',
            'stratum2.ord2.publicntp.net',
            '68.108.190.192',
            'oxygen.neersighted.com',
        ],
        'nescio.wikimedia.org' => [
            'ntp2.proserve.nl',
            'ntp.systemtid.se',
            'tick.jpunix.net',
            'ntp-1.zeroloop.net',
        ],
        'maerlant.wikimedia.org' => [
            'ntp2.proserve.nl',
            'ntp2.stygium.net',
            'tick.jpunix.net',
            'ntp2.roethof.net',
        ],
    }

    # This maps the servers that regular clients use
    $client_upstreams = {
        eqiad => array_concat($wmf_peers['eqiad'], $wmf_peers['codfw']),
        codfw => array_concat($wmf_peers['eqiad'], $wmf_peers['codfw']),
        esams => array_concat($wmf_peers['esams'], $wmf_peers['eqiad']),
        ulsfo => array_concat($wmf_peers['eqiad'], $wmf_peers['codfw']),
    }


    # neon for ntp monitoring queries
    $neon_acl = [
        '208.80.154.14 mask 255.255.255.255',
    ]

    # Required for race-free ntpd startup, see https://bugs.debian.org/cgi-bin/bugreport.cgi?bug=436029 :
    require_package('lockfile-progs')
}
