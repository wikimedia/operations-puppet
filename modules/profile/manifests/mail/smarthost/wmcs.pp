# SPDX-License-Identifier: Apache-2.0
# sets up a mail smarthost for Wikimedia cloud environment
class profile::mail::smarthost::wmcs {

    include network::constants

    class { '::profile::mail::smarthost':
        relay_from_hosts       => $network::constants::labs_networks,
        root_alias_rcpt        => 'root@wmflabs.org',
        envelope_rewrite_rules => [ '*@*.eqiad.wmflabs  root@wmflabs.org  F' ],
    }
}
