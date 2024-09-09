# @summary profile to configure ntp
# @monitoring_hosts list of monitoring hosts
# @ntp_peers list of ntp peers
class profile::ntp (
    Array[Stdlib::Host]                      $monitoring_hosts = lookup('monitoring_hosts'),
    Hash[Wmflib::Sites, Array[Stdlib::Fqdn]] $ntp_peers        = lookup('ntp_peers'),
){
    include network::constants

    # required for monitoring changes to the ntp.conf file
    ensure_packages(['python3-pystemd'])

    # all global peers at all sites
    $wmf_all_peers = flatten(values($ntp_peers))

    # $wmf_server_peers_plus_self is a full list of peer servers applicable at
    # each site (which will, for any given server, also include itself):
    $wmf_server_peers_plus_self = $::site ? {
        # core sites peer with all global peers at all sites
        eqiad   => $wmf_all_peers,
        codfw   => $wmf_all_peers,
        # edge sites only peer with core DCs and themselves:
        default => [$ntp_peers['eqiad'], $ntp_peers['codfw'], $ntp_peers[$::site]].flatten,
    }
    # a server can't peer with itself, so remove self from the list:
    $wmf_server_peers = delete($wmf_server_peers_plus_self, $facts['networking']['fqdn'])

    $pool_zone = $::site ? {
        esams   => 'nl',
        eqsin   => 'sg',
        drmrs   => 'fr',
        magru   => 'br',
        default => 'us',
    }

    $wmf_server_upstream_pools = ["0.${pool_zone}.pool.ntp.org"]
    $wmf_server_upstreams = []

    ### Extra "tos" config for our servers:

    # minsane <N> - the number of acceptably-working pool-servers + peers we
    # must be syncing with to consider *ourselves* to be a reliable source for
    # others. These numbers can be bikeshedded a bit, but the default of 1 is
    # lower than we'd like.  Setting it too high can break time sync in some
    # otherwise-survivable scenarios.  The cores have more local peers between
    # them and greater reliability in general, so they can tolerate a slightly
    # higher number than the edges.
    $minsane = $::site ? {
        eqiad   => 3,
        codfw   => 3,
        default => 2,
    }

    # orphan <stratum> - if no internet servers are reachable, our servers will
    #     operate as an orphaned peer island and maintain some kind of stable
    #     sync with each other.  Without this, if all of our global servers
    #     lost their upstreams, within a few minutes we'd have no time syncing
    #     happening at all ("peer" only protects you from *some* servers losing
    #     upstreams, not all).  A plausible scenario here would be some global
    #     screwup of pool.ntp.org DNS ops.  So set cores to do the orphan job.
    $orphan = $::site ? {
        eqiad   => 12,
        codfw   => 12,
        default => 13,
    }

    # maxclock - This needs to be the sum of:
    #     * The count of servers in wmf_server_peers for this host
    #     * The number (4) we want to use from the "pool" DNS lookup
    #     * One extra to account for the dummy "0.X.pool.ntp.org" entry
    $maxclock = length($wmf_server_peers) + 4 + 1

    # Generate a list of ACLs from "external networks" automatically. We also
    # need 10.0.0.0/8 in addition to these. We cannot use production_networks
    # since that will also include 127.0.0.0/8 and ::1/128.
    $time_acl = $network::constants::external_networks << '10.0.0.0/8'

    ntp::daemon { 'server':
        servers      => $wmf_server_upstreams,
        pools        => $wmf_server_upstream_pools,
        peers        => $wmf_server_peers,
        time_acl     => $time_acl,
        extra_config => "tos minsane ${minsane} orphan ${orphan} maxclock ${maxclock}",
        query_acl    => $monitoring_hosts,
    }

    ferm::service { 'ntp':
        proto  => 'udp',
        port   => 123,
        srange => '($PRODUCTION_NETWORKS $FRACK_NETWORKS $MGMT_NETWORKS $NETWORK_INFRA)',
    }

    monitoring::service { 'ntp peers':
        description   => 'NTP peers',
        check_command => 'check_ntp_peer!0.05!0.1',
        notes_url     => 'https://wikitech.wikimedia.org/wiki/NTP',
    }

    nrpe::plugin { 'check_ntp_service':
        source => 'puppet:///modules/profile/monitoring/check_service_restart.py',
    }

    $services_to_check = {
        'ntpsec.service' => '/etc/ntpsec/ntp.conf',
    }
    $services_to_check.each |$service, $conf_file| {
        nrpe::monitor_service { "check_service_restart_${service}":
            description    => "Check if ${service} has been restarted after ${conf_file} was changed",
            nrpe_command   => "/usr/local/lib/nagios/plugins/check_ntp_service --service ${service} --file ${conf_file} --critical 2",
            sudo_user      => 'root',
            check_interval => 60, # 60mins
            retry_interval => 30, # 30mins
            notes_url      => 'https://wikitech.wikimedia.org/wiki/NTP#Monitoring',
        }
    }

}
