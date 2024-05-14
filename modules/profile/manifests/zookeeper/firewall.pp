# SPDX-License-Identifier: Apache-2.0
# == Class profile::zookeeper::firewall::generic
#
# Firewall rules for a zookeeper cluster
#
# $firewall_access: An array of source sets which are allowed access to Zookeeper
#                   Takes precedence over $srange)
class profile::zookeeper::firewall (
    Optional[String] $srange                 = lookup('profile::zookeeper::firewall::srange'),
    Optional[Array[String]] $firewall_access = lookup('profile::zookeeper::firewall::access'),

){
    if $firewall_access {
        firewall::service { 'zookeeper':
            proto    => 'tcp',
            port     => [2181, 2182, 2183],
            src_sets => $firewall_access,
        }
    } else {
        ferm::service { 'zookeeper':
            proto  => 'tcp',
            # Zookeeper client, protocol ports
            port   => [2181, 2182, 2183],
            srange => $srange,
        }
    }
}
