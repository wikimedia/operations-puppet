# SPDX-License-Identifier: Apache-2.0
class profile::prometheus::ethtool_exporter {
    if ! $facts['is_virtual'] {
        class { 'prometheus::ethtool_exporter':
            ensure => present
        }
    }
}
