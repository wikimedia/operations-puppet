# SPDX-License-Identifier: Apache-2.0

class openstack::neutron::metadata_agent::zed::bookworm(
) {
    require ::openstack::serverpackages::zed::bookworm

    package {'neutron-metadata-agent':
        ensure => 'present',
    }
}
