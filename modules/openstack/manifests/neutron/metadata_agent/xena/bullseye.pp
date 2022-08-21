# SPDX-License-Identifier: Apache-2.0

class openstack::neutron::metadata_agent::xena::bullseye(
) {
    require ::openstack::serverpackages::xena::bullseye

    package {'neutron-metadata-agent':
        ensure => 'present',
    }
}
