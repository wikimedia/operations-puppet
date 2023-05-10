# SPDX-License-Identifier: Apache-2.0
# @summary a profile to allow one to create firewall rules via hiera.  usefull for cloud hosts
# @param services a hash of rules passed to ferm::rule
# @param blocked_ips a list of ip addresses to block
class profile::wmcs::firewall (
    Hash                       $services    = lookup('profile::wmcs::firewall::services'),
    Array[Stdlib::IP::Address] $blocked_ips = lookup('profile::wmcs::firewall::blocked_ips'),
) {
    # We handle firewall rules explicitly in profiles or via requestctl in production
    requires_realm('labs')
    include profile::base::firewall
    $services.each |$service, $config| {
        ferm::service {$service:
            * => $config,
        }
    }
    unless $blocked_ips.empty() {
        ferm::rule { 'drop-reject-from-extras::reject':
            prio => '01',
            rule => "saddr (${blocked_ips.join(' ')}) DROP;",
            desc => 'drop traffic from nets listed in profile::wmcs::firewall::blocked_ips hiera key',
        }
    }
}
