# SPDX-License-Identifier: Apache-2.0

class openstack::neutron::dhcp_agent::zed::bullseye(
) {
    require openstack::serverpackages::zed::bullseye

    package { 'neutron-dhcp-agent':
        ensure => 'present',
    }
}
