# SPDX-License-Identifier: Apache-2.0
# Satisfy the WMF style guide
class profile::alerts::deploy::thanos (
    Hash[Stdlib::Fqdn, Hash] $rule_hosts = lookup('profile::thanos::rule_hosts'),
    Optional[Alerts::Deploy::Transformations] $transformations = lookup('profile::alerts::deploy::thanos::transformations', { default_value => undef }),
) {
    if $facts['networking']['fqdn'] in $rule_hosts {
        class { 'alerts::deploy::thanos':
            transformations => $transformations,
        }
    }
}
