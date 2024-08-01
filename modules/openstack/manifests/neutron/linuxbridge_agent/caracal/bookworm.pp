# SPDX-License-Identifier: Apache-2.0

class openstack::neutron::linuxbridge_agent::caracal::bookworm(
) {
    require ::openstack::serverpackages::caracal::bookworm

    ensure_packages('libosinfo-1.0-0')

    ensure_packages('neutron-linuxbridge-agent')

    # Not installed by default, but still available on Bullseye
    ensure_packages('iptables')

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
