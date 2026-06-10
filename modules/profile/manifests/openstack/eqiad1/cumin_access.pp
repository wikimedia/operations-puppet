# SPDX-License-Identifier: Apache-2.0
class profile::openstack::eqiad1::cumin_access (
    Array[OpenStack::ControlNode] $openstack_control_nodes = lookup('profile::openstack::eqiad1::openstack_control_nodes'),
    Hash[String[1], String[1]] $project_and_security_group_for_cumin_access = lookup('profile::openstack::eqiad1::project_and_security_group_for_cumin_access'),
) {
    class { '::profile::openstack::base::cumin_access':
        openstack_control_nodes                     => $openstack_control_nodes,
        project_and_security_group_for_cumin_access => $project_and_security_group_for_cumin_access,
    }
}
