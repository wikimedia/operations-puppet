# SPDX-License-Identifier: Apache-2.0

class openstack::neutron::common::zed::bullseye(
) {
    require openstack::serverpackages::zed::bullseye

    package { 'neutron-common':
        ensure => 'present',
    }
}
