# SPDX-License-Identifier: Apache-2.0

class openstack::neutron::dhcp_agent::xena::bullseye(
) {
    require openstack::serverpackages::xena::bullseye

    package { 'neutron-dhcp-agent':
        ensure => 'present',
    }
}
