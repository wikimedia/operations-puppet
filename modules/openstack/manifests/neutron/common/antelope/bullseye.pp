# SPDX-License-Identifier: Apache-2.0

class openstack::neutron::common::antelope::bullseye(
) {
    require openstack::serverpackages::antelope::bullseye

    package { 'neutron-common':
        ensure => 'present',
    }
}
