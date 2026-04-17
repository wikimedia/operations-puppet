# SPDX-License-Identifier: Apache-2.0

class openstack::neutron::metadata_agent::flamingo::bookworm(
) {
    package {'neutron-metadata-agent':
        ensure => 'present',
    }
}
