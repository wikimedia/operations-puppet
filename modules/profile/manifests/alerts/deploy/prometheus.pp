# SPDX-License-Identifier: Apache-2.0
# Satisfy the WMF style guide
class profile::alerts::deploy::prometheus {
    class { 'alerts::deploy::prometheus':
        instances => ['analytics', 'ext', 'k8s', 'k8s-staging',
                      'k8s-mlserve', 'ops', 'services']
    }
}
