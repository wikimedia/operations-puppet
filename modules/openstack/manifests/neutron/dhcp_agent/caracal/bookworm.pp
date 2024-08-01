# SPDX-License-Identifier: Apache-2.0

class openstack::neutron::dhcp_agent::caracal::bookworm(
) {
    require openstack::serverpackages::caracal::bookworm

    package { 'neutron-dhcp-agent':
        ensure => 'present',
    }
}
