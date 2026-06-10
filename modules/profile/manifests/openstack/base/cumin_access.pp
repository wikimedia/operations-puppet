# SPDX-License-Identifier: Apache-2.0
class profile::openstack::base::cumin_access (
    Array[OpenStack::ControlNode] $openstack_control_nodes = lookup('profile::openstack::base::openstack_control_nodes'),
    Hash[String[1], String[1]] $project_and_security_group_for_cumin_access = lookup('profile::openstack::base::project_and_security_group_for_cumin_access'),
) {
    # only run on one node
    if $::facts['networking']['fqdn'] == $openstack_control_nodes[0]['host_fqdn'] {
        $ensure = 'present'
    }
    else {
        $ensure = 'absent'
    }
    class { '::openstack::apply_security_groups':
        ensure                     => $ensure,
        project_and_security_group => $project_and_security_group_for_cumin_access,
    }
}
