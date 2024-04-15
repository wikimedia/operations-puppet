# SPDX-License-Identifier: Apache-2.0

class openstack::neutron::l3_agent::bobcat::bookworm(
) {
    require openstack::serverpackages::bobcat::bookworm

    package { 'neutron-l3-agent':
        ensure => 'present',
    }
}
