# SPDX-License-Identifier: Apache-2.0

class openstack::neutron::common::zed::bookworm(
) {
    require openstack::serverpackages::zed::bookworm

    package { 'neutron-common':
        ensure => 'present',
    }
}
