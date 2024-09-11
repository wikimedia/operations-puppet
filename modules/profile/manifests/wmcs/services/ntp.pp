# SPDX-License-Identifier: Apache-2.0
# == Class profile::wmcs::services::ntp
#
# Ntp server profile
class profile::wmcs::services::ntp (
    Array[Stdlib::Host] $server_peers = lookup('profile::wmcs::services::server_peers'),
) {
    include network::constants

    $server_upstream_pools = ['0.us.pool.ntp.org']

    # Keep syncing even if our peer doesn't respond
    $extra_config = 'tos orphan 12'

    $query_acl = []

    $servers = $server_peers.filter |Stdlib::Host $host| { $host != $::facts['networking']['fqdn'] }

    # On Bookworm (or, really, src:ntpsec, but that's replacing src:ntp in Bookworm),
    # we can pass CIDR ranges directly in the config file. For now, we need to pass the
    # netmask in the long format.
    $time_acl = $network::constants::cloud_instance_networks[$::site].map |Stdlib::IP::Address $cidr| {
        $address = $cidr.split('/')[0]
        $mask = wmflib::cidr2mask($cidr)
        "${address} mask ${mask}"
    }

    ntp::daemon { 'server':
        servers      => $servers,
        pools        => $server_upstream_pools,
        time_acl     => $time_acl,
        extra_config => $extra_config,
        query_acl    => $query_acl,
    }

    # FIXME: add monitoring once we decide on a wmcs/services monitoring system
}
