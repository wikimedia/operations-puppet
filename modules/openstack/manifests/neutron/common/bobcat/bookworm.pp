# SPDX-License-Identifier: Apache-2.0

class openstack::neutron::common::bobcat::bookworm(
) {
    require openstack::serverpackages::bobcat::bookworm

    package { 'neutron-common':
        ensure => 'present',
    }
}
