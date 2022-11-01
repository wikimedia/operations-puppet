# SPDX-License-Identifier: Apache-2.0

class openstack::neutron::common::yoga::bullseye(
) {
    require openstack::serverpackages::yoga::bullseye

    package { 'neutron-common':
        ensure => 'present',
    }
}
