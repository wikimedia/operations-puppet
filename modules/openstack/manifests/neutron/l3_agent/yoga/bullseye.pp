# SPDX-License-Identifier: Apache-2.0

class openstack::neutron::l3_agent::yoga::bullseye(
) {
    require openstack::serverpackages::yoga::bullseye

    package { 'neutron-l3-agent':
        ensure => 'present',
    }
}
