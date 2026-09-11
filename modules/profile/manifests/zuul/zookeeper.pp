# SPDX-License-Identifier: Apache-2.0
# new zuul (T393873) - a zookeeper setup as used by zuul (T435186)
class profile::zuul::zookeeper(
    Array[Stdlib::Host] $zuul_nodes = lookup('zuul_main_nodes'),
){

    class { 'profile::zookeeper::server': }

    firewall::service { 'firewall-zookeeper-zuul':
        proto  => 'tcp',
        port   => [2181, 2182, 2183],
        srange => $zuul_nodes,
    }
}
