# SPDX-License-Identifier: Apache-2.0

class openstack::neutron::common::flamingo::trixie(
) {
    package { 'neutron-common':
        ensure => 'present',
    }
}
