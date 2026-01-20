# SPDX-License-Identifier: Apache-2.0

class openstack::neutron::dhcp_agent::flamingo::bookworm(
) {
    require openstack::serverpackages::flamingo::bookworm

    package { 'neutron-dhcp-agent':
        ensure => 'present',
    }
}
