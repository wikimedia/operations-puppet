# SPDX-License-Identifier: Apache-2.0

class openstack::neutron::dhcp_agent::flamingo::trixie(
) {
    package { 'neutron-dhcp-agent':
        ensure => 'present',
    }
}
