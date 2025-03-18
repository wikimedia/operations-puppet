# SPDX-License-Identifier: Apache-2.0

class openstack::neutron::l3_agent::dalmation::bookworm(
) {
    require openstack::serverpackages::dalmation::bookworm

    package { 'neutron-l3-agent':
        ensure => 'present',
    }
}
