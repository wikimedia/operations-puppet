# SPDX-License-Identifier: Apache-2.0
class profile::prometheus::ethtool_exporter {
    class { 'prometheus::ethtool_exporter':
        ensure => present
    }
}
