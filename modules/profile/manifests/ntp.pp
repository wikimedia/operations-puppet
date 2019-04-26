# == Class profile::ntp
#
# Ntp server profile
class profile::ntp (
    Array[String] $monitoring_hosts = hiera('monitoring_hosts', []),
) {
    # A list of all global peers, used in the core sites' case below
    $wmf_all_peers = array_concat(
        $::ntp_peers['eqiad'],
        $::ntp_peers['codfw'],
        $::ntp_peers['esams'],
        $::ntp_peers['ulsfo'],
        $::ntp_peers['eqsin']
    )

    # ntp_peers is a list of peer servers that exist within each site,
    # while wmf_server_peers here is a list of servers a given server should
    # peer with globally, which is in the most-general terms:
    # 1) All peers at both core sites
    # 2) For core sites: All peers at all non-core sites
    # 3) Exclude self from final list
    $wmf_server_peers_plus_self = $::site ? {
        esams   => array_concat($::ntp_peers['eqiad'], $::ntp_peers['codfw'], $::ntp_peers['esams']),
        ulsfo   => array_concat($::ntp_peers['eqiad'], $::ntp_peers['codfw'], $::ntp_peers['ulsfo']),
        eqsin   => array_concat($::ntp_peers['eqiad'], $::ntp_peers['codfw'], $::ntp_peers['eqsin']),
        default => $wmf_all_peers, # core sites
    }
    $wmf_server_peers = delete($wmf_server_peers_plus_self, $::fqdn)

    $pool_zone = $::site ? {
        esams   => 'nl',
        eqsin   => 'sg',
        default => 'us',
    }

    # TODO: generate from $network::constants::aggregate_networks
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

    $wmf_server_upstream_pools = ["0.${pool_zone}.pool.ntp.org"]
    $wmf_server_upstreams = []

    # Extra config only for our servers (not clients):
    # minsane 2 requires 2 (default: 1) sane upstreams/peers present to be in sync
    # maxclock 14 is to better support our large-ish "peer" lists at cores
    #        (if we set it this high non-core, it results in way too many pool peers)
    #        (as we add more edge DCs, we'll need to bump this value by 2 each time)
    #        (could abstract this as $count_ntp_peers + 4)
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

    if hiera('ntp::use_chrony', false) { # lint:ignore:wmf_styleguide
        require ::network::constants
        $chrony_networks_acl = array_concat(['10.0.0.0/8'], $::network::constants::external_networks)

        class { 'ntp::chrony':
            pool               => $wmf_server_upstream_pools,
            permitted_networks => $chrony_networks_acl,
        }
    }
    else {
        ntp::daemon { 'server':
            servers      => $wmf_server_upstreams,
            pools        => $wmf_server_upstream_pools,
            peers        => $wmf_server_peers,
            time_acl     => $our_networks_acl,
            extra_config => $extra_config,
            query_acl    => $monitoring_hosts,
        }
    }

    ferm::service { 'ntp':
        proto => 'udp',
        port  => 'ntp',
    }

    monitoring::service { 'ntp peers':
        description   => 'NTP peers',
        check_command => 'check_ntp_peer!0.1!0.5',
        notes_url     => 'https://wikitech.wikimedia.org/wiki/NTP',
    }

}
