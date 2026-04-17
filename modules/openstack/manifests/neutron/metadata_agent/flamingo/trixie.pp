# SPDX-License-Identifier: Apache-2.0

class openstack::neutron::metadata_agent::flamingo::trixie(
) {
    package {'neutron-metadata-agent':
        ensure => 'present',
    }
}
