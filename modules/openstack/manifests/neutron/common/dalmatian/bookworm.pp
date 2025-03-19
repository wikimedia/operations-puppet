# SPDX-License-Identifier: Apache-2.0

class openstack::neutron::common::dalmatian::bookworm(
) {
    require openstack::serverpackages::dalmatian::bookworm

    package { 'neutron-common':
        ensure => 'present',
    }
}
