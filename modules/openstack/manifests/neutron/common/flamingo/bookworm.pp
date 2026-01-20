# SPDX-License-Identifier: Apache-2.0

class openstack::neutron::common::flamingo::bookworm(
) {
    require openstack::serverpackages::flamingo::bookworm

    package { 'neutron-common':
        ensure => 'present',
    }
}
