# SPDX-License-Identifier: Apache-2.0

class openstack::neutron::l3_agent::antelope::bullseye(
) {
    require openstack::serverpackages::antelope::bullseye

    package { 'neutron-l3-agent':
        ensure => 'present',
    }
}
