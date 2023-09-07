# SPDX-License-Identifier: Apache-2.0

class openstack::neutron::dhcp_agent::zed::bookworm(
) {
    require openstack::serverpackages::zed::bookworm

    package { 'neutron-dhcp-agent':
        ensure => 'present',
    }
}
