# SPDX-License-Identifier: Apache-2.0

class openstack::neutron::common::dalmation::bookworm(
) {
    require openstack::serverpackages::dalmation::bookworm

    package { 'neutron-common':
        ensure => 'present',
    }
}
