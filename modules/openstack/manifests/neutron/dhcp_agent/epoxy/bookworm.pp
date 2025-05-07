# SPDX-License-Identifier: Apache-2.0

class openstack::neutron::dhcp_agent::epoxy::bookworm(
) {
    require openstack::serverpackages::epoxy::bookworm

    package { 'neutron-dhcp-agent':
        ensure => 'present',
    }
}
