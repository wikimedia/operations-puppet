# SPDX-License-Identifier: Apache-2.0

class openstack::neutron::metadata_agent::bobcat::bookworm(
) {
    require ::openstack::serverpackages::bobcat::bookworm

    package {'neutron-metadata-agent':
        ensure => 'present',
    }
}
