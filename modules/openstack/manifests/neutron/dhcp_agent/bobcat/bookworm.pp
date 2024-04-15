# SPDX-License-Identifier: Apache-2.0

class openstack::neutron::dhcp_agent::bobcat::bookworm(
) {
    require openstack::serverpackages::bobcat::bookworm

    package { 'neutron-dhcp-agent':
        ensure => 'present',
    }
}
