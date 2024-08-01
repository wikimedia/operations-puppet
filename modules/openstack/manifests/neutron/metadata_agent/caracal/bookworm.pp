# SPDX-License-Identifier: Apache-2.0

class openstack::neutron::metadata_agent::caracal::bookworm(
) {
    require ::openstack::serverpackages::caracal::bookworm

    package {'neutron-metadata-agent':
        ensure => 'present',
    }
}
