# SPDX-License-Identifier: Apache-2.0
# @summary converts a list of hosts to a list of ip addresses
# @param hosts a list of hosts to convert
function wmflib::hosts2ips (
    Array[Variant[Stdlib::Host, Stdlib::IP::Address]] $hosts,
) >> Array[Stdlib::IP::Address] {
    $hosts.map |$host| {
        $host ? {
            Stdlib::IP::Address => $host,
            default             => dnsquery::lookup($host, true)
        }
    }.flatten.sort
}
