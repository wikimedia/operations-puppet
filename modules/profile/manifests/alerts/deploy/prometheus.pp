# SPDX-License-Identifier: Apache-2.0
# Satisfy the WMF style guide
class profile::alerts::deploy::prometheus (
    Optional[Alerts::Deploy::Transformations] $transformations = lookup('profile::alerts::deploy::prometheus::transformations', { default_value => undef }),
) {
    class { 'alerts::deploy::prometheus':
        instances       => prometheus::instances().keys().sort(),
        transformations => $transformations,
    }
}
