# SPDX-License-Identifier: Apache-2.0
# == Class profile::zookeeper::firewall::generic
#
# Firewall rules for a zookeeper cluster
#
# $firewall_access: An array of source sets which are allowed access to Zookeeper
#                   Takes precedence over $srange)
class profile::zookeeper::firewall (
    Array[String] $firewall_access = lookup('profile::zookeeper::firewall::access'),

){
    firewall::service { 'zookeeper':
        proto    => 'tcp',
        port     => [2181, 2182, 2183],
        src_sets => $firewall_access,
    }
}
