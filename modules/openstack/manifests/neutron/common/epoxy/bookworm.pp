# SPDX-License-Identifier: Apache-2.0

class openstack::neutron::common::epoxy::bookworm(
) {
    require openstack::serverpackages::epoxy::bookworm

    package { 'neutron-common':
        ensure => 'present',
    }
}
