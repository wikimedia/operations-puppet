# SPDX-License-Identifier: Apache-2.0

class openstack::neutron::metadata_agent::epoxy::trixie(
) {
    require ::openstack::serverpackages::epoxy::trixie

    package {'neutron-metadata-agent':
        ensure => 'present',
    }
}
