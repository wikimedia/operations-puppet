# SPDX-License-Identifier: Apache-2.0

class openstack::neutron::dhcp_agent::dalmation::bookworm(
) {
    require openstack::serverpackages::dalmation::bookworm

    package { 'neutron-dhcp-agent':
        ensure => 'present',
    }
}
