# SPDX-License-Identifier: Apache-2.0
class profile::openstack::base::networktests (
    String[1]                     $region                  = lookup('porfile::openstack::base::region'),
    Stdlib::Fqdn                  $sshbastion              = lookup('profile::openstack::base::networktests::sshbastion'),
    Hash                          $envvars                 = lookup('profile::openstack::base::networktests::envvars'),
    Array[OpenStack::ControlNode] $openstack_control_nodes = lookup('profile::openstack::base::openstack_control_nodes'),
) {
    class { 'cmd_checklist_runner': }

    class { 'openstack::monitor::networktests':
        timer_active => false, # not providing a lot of value today
        #timer_active => ($::facts['networking']['fqdn'] == $openstack_control_nodes[1]['host_fqdn']), # not [0] because decoupling
        region       => $region,
        sshbastion   => $sshbastion,
        envvars      => $envvars,
    }
}
