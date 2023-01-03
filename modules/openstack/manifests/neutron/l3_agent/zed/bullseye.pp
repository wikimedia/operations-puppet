# SPDX-License-Identifier: Apache-2.0

class openstack::neutron::l3_agent::zed::bullseye(
) {
    require openstack::serverpackages::zed::bullseye

    package { 'neutron-l3-agent':
        ensure => 'present',
    }
}
