# == Class profile::ntp
#
# Ntp server profile
class profile::ntp {

    $wmf_peers = $::standard::ntp::wmf_peers
    # Combines the peers above into a single list
    $wmf_all_peers = array_concat(
        $wmf_peers['eqiad'],
        $wmf_peers['codfw'],
        $wmf_peers['esams'],
        $wmf_peers['ulsfo'],
        $wmf_peers['eqsin']
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
    # Updated Apr 2017 (correcting only disfunctional ones)
    # These are the pool servers used by the peers above
    $peer_upstreams = {
        'chromium.wikimedia.org' => [
            'ac-ntp1.net.cmu.edu',
            'tock.teljet.net',
            'e.time.steadfast.net',
            'ntp-3.vt.edu',
        ],
        'hydrogen.wikimedia.org' => [
            'ac-ntp2.net.cmu.edu',
            'tick.teljet.net',
            'f.time.steadfast.net',
            'ntp3.servman.ca',
        ],
        'acamar.wikimedia.org' => [
            'tick.binary.net',
            'ntp8.smatwebdesign.com',
            'tick.ellipse.net',
            'jarvis.arlen.io',
        ],
        'achernar.wikimedia.org' => [
            'tock.binary.net',
            'ntp9.smatwebdesign.com',
            'tock.ellipse.net',
            '72.14.183.239',
        ],
        'nescio.wikimedia.org' => [
            'ntp2.proserve.nl',
            'ntp.systemtid.se',
            'ntp.terwan.nl',
            'ntp1.linocomm.net',
        ],
        'maerlant.wikimedia.org' => [
            'ntp1.proserve.nl',
            'ntp-de.stygium.net',
            'ntp.syari.net',
            'time1.bokke.rs',
        ],
    }

    # TODO: generate from $network::constants::all_networks
    $our_networks_acl = [
      '10.0.0.0 mask 255.0.0.0',
      '208.80.152.0 mask 255.255.252.0',
      '91.198.174.0 mask 255.255.255.0',
      '198.35.26.0 mask 255.255.254.0',
      '185.15.56.0 mask 255.255.252.0',
      '103.102.166.0 mask 255.255.255.0',
      '2620:0:860:: mask ffff:ffff:fffc::',
      '2a02:ec80:: mask ffff:ffff::',
      '2001:df2:e500:: mask ffff:ffff:ffff::',
    ]


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
