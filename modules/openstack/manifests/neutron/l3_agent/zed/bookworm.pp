# SPDX-License-Identifier: Apache-2.0

class openstack::neutron::l3_agent::zed::bookworm(
) {
    require openstack::serverpackages::zed::bookworm

    package { 'neutron-l3-agent':
        ensure => 'present',
    }
}
