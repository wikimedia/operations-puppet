# SPDX-License-Identifier: Apache-2.0

class openstack::neutron::dhcp_agent::yoga::bullseye(
) {
    require openstack::serverpackages::yoga::bullseye

    package { 'neutron-dhcp-agent':
        ensure => 'present',
    }
}
