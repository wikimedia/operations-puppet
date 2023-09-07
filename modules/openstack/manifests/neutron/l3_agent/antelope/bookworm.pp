# SPDX-License-Identifier: Apache-2.0

class openstack::neutron::l3_agent::antelope::bookworm(
) {
    require openstack::serverpackages::antelope::bookworm

    package { 'neutron-l3-agent':
        ensure => 'present',
    }
}
