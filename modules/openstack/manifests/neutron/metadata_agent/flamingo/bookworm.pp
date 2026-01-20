# SPDX-License-Identifier: Apache-2.0

class openstack::neutron::metadata_agent::flamingo::bookworm(
) {
    require ::openstack::serverpackages::flamingo::bookworm

    package {'neutron-metadata-agent':
        ensure => 'present',
    }
}
