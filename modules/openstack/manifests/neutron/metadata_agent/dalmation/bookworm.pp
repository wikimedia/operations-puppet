# SPDX-License-Identifier: Apache-2.0

class openstack::neutron::metadata_agent::dalmation::bookworm(
) {
    require ::openstack::serverpackages::dalmation::bookworm

    package {'neutron-metadata-agent':
        ensure => 'present',
    }
}
