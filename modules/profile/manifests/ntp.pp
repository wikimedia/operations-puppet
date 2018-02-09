# == Class profile::ntp
#
# Ntp server profile
class profile::ntp {

    $wmf_peers = $::standard::ntp::wmf_peers

    # A list of all global peers, used in the core sites' case below
    $wmf_all_peers = array_concat(
        $wmf_peers['eqiad'],
        $wmf_peers['codfw'],
        $wmf_peers['esams'],
        $wmf_peers['ulsfo'],
        $wmf_peers['eqsin']
    )

    # wmf_peers is a list of peer servers that exist within each site,
    # while wmf_server_peers here is a list of servers a given server should
    # peer with globally, which is in the most-general terms:
    # 1) All peers at both core sites
    # 2) For core sites: All peers at all non-core sites
    # 3) Exclude self from final list
    $wmf_server_peers_plus_self = $::site ? {
        esams   => array_concat($wmf_peers['eqiad'], $wmf_peers['codfw'], $wmf_peers['esams']),
        ulsfo   => array_concat($wmf_peers['eqiad'], $wmf_peers['codfw'], $wmf_peers['ulsfo']),
        eqsin   => array_concat($wmf_peers['eqiad'], $wmf_peers['codfw'], $wmf_peers['eqsin']),
        default => $wmf_all_peers, # core sites
    }
    $wmf_server_peers = delete($wmf_server_peers_plus_self, $::fqdn)

    # Legacy manual peer lists, for pre- stretch systems that lack ntpd with
    # "restrict source" functionality and proper "pool" behavior
    # Last Updated Apr 2017 (correcting only disfunctional ones)
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

    # Pooling configuration for stretch+ ntp versions:
    $pool_zone = $::site ? {
        esams   => 'nl',
        eqsin   => 'sg',
        default => 'us',
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

    if os_version('debian >= stretch') {
        $wmf_server_upstream_pools = ["0.${pool_zone}.pool.ntp.org"]
        $wmf_server_upstreams = []
    } else {
        $wmf_server_upstream_pools = []
        $wmf_server_upstreams = $peer_upstreams[$::fqdn]
    }

    # Extra config only for our servers (not clients):
    # minsane 2 requires 2 (default: 1) sane upstreams/peers present to be in sync
    # maxclock 14 is to better support our large-ish "peer" lists at cores
    #        (if we set it this high non-core, it results in way too many pool peers)
    #        (as we add more edge DCs, we'll need to bump this value by 2 each time)
    #        (could abstract this as $count_wmf_peers + 4)
    # orphan <stratum> - if no internet servers are reachable, our servers will
    #     operate as an orphaned peer island and maintain some kind of stable
    #     sync with each other.  Without this, if all of our global servers
    #     lost their upstreams, within a few minutes we'd have no time syncing
    #     happening at all ("peer" only protects you from some servers losing
    #     upstreams, not all).  A plausible scenario here would be some global
    #     screwup of pool.ntp.org DNS ops.  So set cores to do the orphan job.
    $extra_config = $::site ? {
        eqiad   => 'tos maxclock 14 minsane 2 orphan 12',
        codfw   => 'tos maxclock 14 minsane 2 orphan 12',
        default => 'tos minsane 2 orphan 13',
    }

    ntp::daemon { 'server':
        servers      => $wmf_server_upstreams,
        pools        => $wmf_server_upstream_pools,
        peers        => $wmf_server_peers,
        time_acl     => $our_networks_acl,
        extra_config => $extra_config,
        query_acl    => $::standard::ntp::monitoring_acl,
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
