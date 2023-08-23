# SPDX-License-Identifier: Apache-2.0

class openstack::neutron::dhcp_agent::antelope::bullseye(
) {
    require openstack::serverpackages::antelope::bullseye

    package { 'neutron-dhcp-agent':
        ensure => 'present',
    }
}
