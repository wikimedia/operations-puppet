# SPDX-License-Identifier: Apache-2.0
# @summary Create a named set to be used in httpd rules
# @param ensure Ensure of the resource
# @param hosts An array of FQDNs, IPs or subnets. Hostnames are being resolved
#              at runtime towards IP addresses
define gerrit::proxy::set (
    Array[Wmflib::Host_or_network] $hosts,
    Wmflib::Ensure                 $ensure = present,
) {
    $ips = $hosts.map |$host| {
        $host ? {
            Stdlib::IP::Address => $host,
            default             => dnsquery::lookup($host, true),
        }
    }.flatten.unique

    $ipv4_addrs = $ips.filter |$a| { $a =~ Stdlib::IP::Address::V4 }
    $ipv6_addrs = $ips.filter |$a| { $a =~ Stdlib::IP::Address::V6 }

    $v4_params = {
        'name'     => "${title}_ipv4",
        'family'   => 'v4',
        'addrs'    => $ipv4_addrs,
    }
    $v6_params = {
        'name'     => "${title}_ipv6",
        'family'   => 'v6',
        'addrs'    => $ipv6_addrs,
    }

    $base    = sprintf('%02d-%s', 50, $title)
    $file_v4 = "/etc/apache2/conf-enabled/${base}-v4.conf"
    $file_v6 = "/etc/apache2/conf-enabled/${base}-v6.conf"

    file { $file_v4:
        ensure  => $ensure,
        owner   => 'root',
        group   => 'root',
        mode    => '0444',
        content => epp('profile/gerrit/proxy/qos-sets.epp', $v4_params),
        notify  => Service['apache2'],
    }

    file { $file_v6:
        ensure  => $ensure,
        owner   => 'root',
        group   => 'root',
        mode    => '0444',
        content => epp('profile/gerrit/proxy/qos-sets.epp', $v6_params),
        notify  => Service['apache2'],
    }
}
