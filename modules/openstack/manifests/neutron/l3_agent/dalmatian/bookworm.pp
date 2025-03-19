# SPDX-License-Identifier: Apache-2.0

class openstack::neutron::l3_agent::dalmatian::bookworm(
) {
    require openstack::serverpackages::dalmatian::bookworm

    package { 'neutron-l3-agent':
        ensure => 'present',
    }
}
