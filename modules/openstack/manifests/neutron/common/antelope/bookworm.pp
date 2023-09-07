# SPDX-License-Identifier: Apache-2.0

class openstack::neutron::common::antelope::bookworm(
) {
    require openstack::serverpackages::antelope::bookworm

    package { 'neutron-common':
        ensure => 'present',
    }
}
