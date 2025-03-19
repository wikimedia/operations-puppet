# SPDX-License-Identifier: Apache-2.0

class openstack::neutron::dhcp_agent::dalmatian::bookworm(
) {
    require openstack::serverpackages::dalmatian::bookworm

    package { 'neutron-dhcp-agent':
        ensure => 'present',
    }
}
