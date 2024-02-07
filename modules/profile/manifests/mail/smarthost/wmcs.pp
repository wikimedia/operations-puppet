# SPDX-License-Identifier: Apache-2.0
# sets up a mail smarthost for Wikimedia cloud environment
class profile::mail::smarthost::wmcs (
    Array[Wmflib::Host::Wildcard] $internal_domains = lookup('profile::mail::smarthost::wmcs::internal_domains'),
    Stdlib::Fqdn                  $external_domain  = lookup('profile::mail::smarthost::wmcs::external_domain'),
) {
    include network::constants

    $rewrite_rules = $internal_domains.map |Wmflib::Host::Wildcard $x| {
        "*@*.${x}  root@${external_domain}  F"
    }

    class { '::profile::mail::smarthost':
        relay_from_hosts       => $network::constants::cloud_networks,
        root_alias_rcpt        => "root@${external_domain}",
        envelope_rewrite_rules => $rewrite_rules,
    }
}
