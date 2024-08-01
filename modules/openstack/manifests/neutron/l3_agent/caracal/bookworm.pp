# SPDX-License-Identifier: Apache-2.0

class openstack::neutron::l3_agent::caracal::bookworm(
) {
    require openstack::serverpackages::caracal::bookworm

    package { 'neutron-l3-agent':
        ensure => 'present',
    }
}
