# SPDX-License-Identifier: Apache-2.0
# @summary configure ferm rules for rsync mirroring
# @param internal_rsync_clients list of internal rsync clients
# @param rsync_mirrors object representing a mirror
class profile::dumps::distribution::ferm (
    Array[Stdlib::Fqdn] $internal_rsync_clients = lookup('profile::dumps::rsync_internal_clients'),
    Array[Wmflib::Dumps::Mirror] $rsync_mirrors = lookup('profile::dumps::distribution::mirrors'),
) {
    $rsync_clients = $rsync_mirrors.filter |$item| {
        $item['active'] == 'yes'
    }.map |$item| {
        $item['ipv4'].map |$ip| {
            $ip ? {
                Stdlib::IP::Address::V4 => $ip,
                default                 => dnsquery::a($ip),
            }
        } +
        $item['ipv6'].map |$ip| {
            $ip ? {
                Stdlib::IP::Address::V6 => $ip,
                default                 => dnsquery::aaaa($ip),
            }
        }
    } + $internal_rsync_clients.map |$item| { dnsquery::lookup($item) }

    $_rsync_clients = $rsync_clients.flatten.sort.unique

    firewall::service { 'dumps_rsyncd':
        port   => 873,
        proto  => 'tcp',
        srange => $_rsync_clients,
    }
}
