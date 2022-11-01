# SPDX-License-Identifier: Apache-2.0

class openstack::neutron::metadata_agent::yoga::bullseye(
) {
    require ::openstack::serverpackages::yoga::bullseye

    package {'neutron-metadata-agent':
        ensure => 'present',
    }
}
