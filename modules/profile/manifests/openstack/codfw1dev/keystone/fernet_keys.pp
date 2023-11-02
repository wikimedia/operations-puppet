# SPDX-License-Identifier: Apache-2.0
class profile::openstack::codfw1dev::keystone::fernet_keys(
    Array[OpenStack::ControlNode] $openstack_control_nodes = lookup('profile::openstack::codfw1dev::openstack_control_nodes'),
) {
    class {'profile::openstack::base::keystone::fernet_keys':
        openstack_control_nodes => $openstack_control_nodes,
    }
}
