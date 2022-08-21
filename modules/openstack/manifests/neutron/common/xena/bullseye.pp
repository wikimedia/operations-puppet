# SPDX-License-Identifier: Apache-2.0

class openstack::neutron::common::xena::bullseye(
) {
    require openstack::serverpackages::xena::bullseye

    package { 'neutron-common':
        ensure => 'present',
    }
}
