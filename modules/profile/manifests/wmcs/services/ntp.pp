# SPDX-License-Identifier: Apache-2.0
# == Class profile::wmcs::services::ntp
#
# Ntp server profile
class profile::wmcs::services::ntp(
    Array[Stdlib::Host] $server_peers = lookup('profile::wmcs::services::server_peers'),
    Array[String] $networks_acl = lookup('profile::wmcs::services::wmcs_networks_acl',
    { 'default_value' => [ '172.16.0.0 mask 255.255.248.0', '10.68.16.0 mask 255.255.248.0' ] }),
){
    $server_upstream_pools = ['0.us.pool.ntp.org']

    # Keep syncing even if our peer doesn't respond
    $extra_config = 'tos orphan 12'

    $query_acl = []
    $server_upstreams = []

    $peers = $server_peers.filter |Stdlib::Host $host| { $host != $::facts['networking']['fqdn'] }

    ntp::daemon { 'server':
        servers      => $server_upstreams,
        pools        => $server_upstream_pools,
        peers        => $peers,
        time_acl     => $networks_acl,
        extra_config => $extra_config,
        query_acl    => $query_acl,
    }

    # FIXME: add monitoring once we decide on a wmcs/services monitoring system
}
