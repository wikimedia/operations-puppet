# SPDX-License-Identifier: Apache-2.0
# == Class profile::zookeeper::firewall::generic
#
# Firewall rules for a zookeeper cluster
#
# $firewall_access: An array of source sets which are allowed access to Zookeeper
#
# $firewall_access_hosts: An array of hosts which are allowed access to Zookeeper
class profile::zookeeper::firewall (
    Optional[Array[String]]             $firewall_access = lookup('profile::zookeeper::firewall::access', { 'default_value' => undef }),
    Optional[Array[Stdlib::Host]] $firewall_access_hosts = lookup('profile::zookeeper::firewall::access::hosts', { 'default_value' => undef }),

){
    if $firewall_access == undef and $firewall_access_hosts == undef {
        fail('you must provide either $firewall_access or $firewall_access_hosts')
    }

    if $firewall_access {
        firewall::service { 'zookeeper':
            proto    => 'tcp',
            port     => [2181, 2182, 2183],
            src_sets => $firewall_access,
        }
    }

    if $firewall_access_hosts {
        firewall::service { 'zookeeper':
            proto  => 'tcp',
            port   => [2181, 2182, 2183],
            srange => $firewall_access_hosts,
        }
    }
}
