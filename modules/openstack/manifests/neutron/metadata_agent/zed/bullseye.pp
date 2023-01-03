# SPDX-License-Identifier: Apache-2.0

class openstack::neutron::metadata_agent::zed::bullseye(
) {
    require ::openstack::serverpackages::zed::bullseye

    package {'neutron-metadata-agent':
        ensure => 'present',
    }
}
