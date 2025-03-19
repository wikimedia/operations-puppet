# SPDX-License-Identifier: Apache-2.0

class openstack::neutron::metadata_agent::dalmatian::bookworm(
) {
    require ::openstack::serverpackages::dalmatian::bookworm

    package {'neutron-metadata-agent':
        ensure => 'present',
    }
}
