# SPDX-License-Identifier: Apache-2.0
# @summary Create a named set to be used in nftables rules
# @param ensure Ensure of the resource
# @param hosts An array of FQDNs, IPs or subnets. Hostnames are being resolved
#              at runtime towards IP addresses
define nftables::set (
    Array[Wmflib::Host_or_network] $hosts,
    Wmflib::Ensure $ensure = present,
) {

    $ips = $hosts.map |$host| {
        $host ? {
            Stdlib::IP::Address => $host,
            default => dnsquery::lookup($host, true)
        }
    }.flatten.unique

    $ipv4_addrs = $ips.filter |$host| { $host =~ Stdlib::IP::Address::V4 }
    $ipv6_addrs = $ips.filter |$host| { $host =~ Stdlib::IP::Address::V6 }

    $v4_params = {
        'name'     => "${title}_v4",
        'set_type' => 'ipv4_addr',
        'addrs'    => $ipv4_addrs,
        'interval' => $ipv4_addrs.any |$addr| { '/' in $addr },
    }
    @file { "/etc/nftables/sets/${name}_ipv4.nft":
        ensure  => $ensure,
        mode    => '0444',
        content => epp('nftables/set.epp', $v4_params),
        notify  => Service['nftables'],
        tag     => 'nft',
    }

    $v6_params = {
        'name'     => "${title}_v6",
        'set_type' => 'ipv6_addr',
        'addrs'    => $ipv6_addrs,
        'interval' => $ipv6_addrs.any |$addr| { '/' in $addr }
    }
    @file { "/etc/nftables/sets/${name}_ipv6.nft":
        ensure  => $ensure,
        mode    => '0444',
        content => epp('nftables/set.epp', $v6_params),
        notify  => Service['nftables'],
        tag     => 'nft',
    }
}
