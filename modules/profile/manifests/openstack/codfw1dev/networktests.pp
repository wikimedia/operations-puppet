# SPDX-License-Identifier: Apache-2.0
class profile::openstack::codfw1dev::networktests (
    Stdlib::Fqdn                  $sshbastion              = lookup('profile::openstack::codfw1dev::networktests::sshbastion'),
    Hash                          $envvars                 = lookup('profile::openstack::codfw1dev::networktests::envvars'),
    Array[OpenStack::ControlNode] $openstack_control_nodes = lookup('profile::openstack::codfw1dev::openstack_control_nodes'),
) {
    class { 'profile::openstack::base::networktests':
        region                  => 'codfw1dev',
        sshbastion              => $sshbastion,
        envvars                 => $envvars,
        openstack_control_nodes => $openstack_control_nodes,
    }
}
