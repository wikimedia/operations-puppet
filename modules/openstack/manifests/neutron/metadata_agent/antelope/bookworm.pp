# SPDX-License-Identifier: Apache-2.0

class openstack::neutron::metadata_agent::antelope::bookworm(
) {
    require ::openstack::serverpackages::antelope::bookworm

    package {'neutron-metadata-agent':
        ensure => 'present',
    }
}
