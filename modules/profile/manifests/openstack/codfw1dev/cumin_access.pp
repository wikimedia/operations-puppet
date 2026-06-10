# SPDX-License-Identifier: Apache-2.0
class profile::openstack::codfw1dev::cumin_access (
    Array[OpenStack::ControlNode] $openstack_control_nodes = lookup('profile::openstack::codfw1dev::openstack_control_nodes'),
    Hash[String[1], String[1]] $project_and_security_group_for_cumin_access = lookup('profile::openstack::codfw1dev::project_and_security_group_for_cumin_access'),
) {
    class { '::profile::openstack::base::cumin_access':
        openstack_control_nodes                     => $openstack_control_nodes,
        project_and_security_group_for_cumin_access => $project_and_security_group_for_cumin_access,
    }
}
