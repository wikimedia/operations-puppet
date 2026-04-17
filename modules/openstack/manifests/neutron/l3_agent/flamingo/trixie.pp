# SPDX-License-Identifier: Apache-2.0

class openstack::neutron::l3_agent::flamingo::trixie(
) {
    package { 'neutron-l3-agent':
        ensure => 'present',
    }

    # Needed by wmcs-netns-events
    package { 'python3-pyinotify':
        ensure => 'present',
    }
}
