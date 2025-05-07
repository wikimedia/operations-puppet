# SPDX-License-Identifier: Apache-2.0

class openstack::neutron::l3_agent::epoxy::bookworm(
) {
    require openstack::serverpackages::epoxy::bookworm

    package { 'neutron-l3-agent':
        ensure => 'present',
    }
}
