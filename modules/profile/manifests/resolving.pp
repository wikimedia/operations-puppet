# SPDX-License-Identifier: Apache-2.0
class profile::resolving (
    Integer[1,30]       $timeout             = lookup('profile::resolving::timeout'),
    Integer[1,5]        $ndots               = lookup('profile::resolving::ndots'),
    Integer[1,5]        $attempts            = lookup('profile::resolving::attempts'),
    Boolean             $disable_resolvconf  = lookup('profile::resolving::disable_resolvconf'),
    Boolean             $disable_dhcpupdates = lookup('profile::resolving::disable_dhcpupdates'),
    Array[Stdlib::Fqdn] $domain_search       = lookup('profile::resolving::domain_search'),
    Array[Stdlib::Host] $nameservers         = lookup('profile::resolving::nameservers'),
){
    class {'resolvconf':
        domain_search       => $domain_search,
        nameservers         => $nameservers,
        timeout             => $timeout,
        attempts            => $attempts,
        ndots               => $ndots,
        disable_resolvconf  => $disable_resolvconf,
        disable_dhcpupdates => $disable_resolvconf,
    }
    $nameserver_ips = $resolvconf::nameserver_ips
}
