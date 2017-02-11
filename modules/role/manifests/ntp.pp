# == Class role::ntp
#
# Ntp server role
class role::ntp {
    include ::standard::ntp
    system::role { 'ntp': description => 'NTP server' }

    $wmf_peers = $::standard::ntp::wmf_peers
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

    # TODO: generate from $network::constants::all_networks
    $our_networks_acl = [
      '10.0.0.0 mask 255.0.0.0',
      '208.80.152.0 mask 255.255.252.0',
      '91.198.174.0 mask 255.255.255.0',
      '198.35.26.0 mask 255.255.254.0',
      '185.15.56.0 mask 255.255.252.0',
      '2620:0:860:: mask ffff:ffff:fffc::',
      '2a02:ec80:: mask ffff:ffff::',]


    ntp::daemon { 'server':
        servers   => $peer_upstreams[$::fqdn],
        peers     => delete($wmf_all_peers, $::fqdn),
        time_acl  => $our_networks_acl,
        query_acl => $::standard::ntp::monitoring_acl,
    }

    ferm::service { 'ntp':
        proto => 'udp',
        port  => 'ntp',
    }

    monitoring::service { 'ntp peers':
        description   => 'NTP peers',
        check_command => 'check_ntp_peer!0.1!0.5';
    }

}
