# SPDX-License-Identifier: Apache-2.0

class openstack::neutron::dhcp_agent::antelope::bookworm(
) {
    require openstack::serverpackages::antelope::bookworm

    package { 'neutron-dhcp-agent':
        ensure => 'present',
    }
}
