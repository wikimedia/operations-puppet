# SPDX-License-Identifier: Apache-2.0
# Satisfy the WMF style guide
class profile::alerts::deploy::prometheus {
    class { 'alerts::deploy::prometheus':
        instances => prometheus::instances().keys().sort(),
    }
}
