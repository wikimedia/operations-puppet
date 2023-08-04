# SPDX-License-Identifier: Apache-2.0
# == Class profile::zookeeper::firewall::generic
#
# Firewall rules for a zookeeper cluster.
#
class profile::zookeeper::firewall (
    String $srange = lookup('profile::zookeeper::firewall::srange'),
){

    ferm::service { 'zookeeper':
        proto  => 'tcp',
        # Zookeeper client, protocol ports
        port   => [2181, 2182, 2183],
        srange => $srange,
    }
}
