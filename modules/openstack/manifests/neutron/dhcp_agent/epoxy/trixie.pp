# SPDX-License-Identifier: Apache-2.0

class openstack::neutron::dhcp_agent::epoxy::trixie(
) {
    require openstack::serverpackages::epoxy::trixie

    package { 'neutron-dhcp-agent':
        ensure => 'present',
    }
}
