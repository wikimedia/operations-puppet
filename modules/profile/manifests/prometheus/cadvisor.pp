# SPDX-License-Identifier: Apache-2.0
class profile::prometheus::cadvisor {
    class { 'prometheus::cadvisor':
        port   => 4194,
        ensure => 'present',
    }
}
