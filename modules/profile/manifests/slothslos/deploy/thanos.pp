# SPDX-License-Identifier: Apache-2.0
# Satisfy the WMF style guide
class profile::slothslos::deploy::thanos (
    Hash[Stdlib::Fqdn, Hash] $rule_hosts = lookup('profile::thanos::rule_hosts'),
) {
    if $facts['networking']['fqdn'] in $rule_hosts {
        slothslos::deploy::thanos { 'main': }
    }
}
