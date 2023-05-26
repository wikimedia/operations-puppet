# SPDX-License-Identifier: Apache-2.0
class profile::prometheus::cadvisor (
    Wmflib::Ensure $ensure = lookup('profile::prometheus::cadvisor::ensure'),
) {
    class { 'prometheus::cadvisor':
        port   => 4194,
        ensure => $ensure,
    }
}
