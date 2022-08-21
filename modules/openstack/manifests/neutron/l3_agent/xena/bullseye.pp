# SPDX-License-Identifier: Apache-2.0

class openstack::neutron::l3_agent::xena::bullseye(
) {
    require openstack::serverpackages::xena::bullseye

    package { 'neutron-l3-agent':
        ensure => 'present',
    }
}
