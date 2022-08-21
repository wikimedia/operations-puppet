# SPDX-License-Identifier: Apache-2.0

class openstack::neutron::linuxbridge_agent::xena::bullseye(
) {
    require ::openstack::serverpackages::xena::bullseye

    package { 'libosinfo-1.0-0':
        ensure => 'present',
    }

    package { 'neutron-linuxbridge-agent':
        ensure => 'present',
    }

    # Not installed by default, but still available on Bullseye
    package { 'iptables':
        ensure => 'present',
    }

    alternatives::select { 'iptables':
        path => '/usr/sbin/iptables-legacy',
    }
    alternatives::select { 'ip6tables':
        path => '/usr/sbin/ip6tables-legacy',
    }
    alternatives::select { 'ebtables':
        path    => '/usr/sbin/ebtables-legacy',
    }
}
