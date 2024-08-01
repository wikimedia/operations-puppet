# SPDX-License-Identifier: Apache-2.0

class openstack::neutron::common::caracal::bookworm(
) {
    require openstack::serverpackages::caracal::bookworm

    package { 'neutron-common':
        ensure => 'present',
    }
}
