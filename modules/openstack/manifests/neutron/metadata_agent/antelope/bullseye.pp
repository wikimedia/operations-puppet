# SPDX-License-Identifier: Apache-2.0

class openstack::neutron::metadata_agent::antelope::bullseye(
) {
    require ::openstack::serverpackages::antelope::bullseye

    package {'neutron-metadata-agent':
        ensure => 'present',
    }
}
