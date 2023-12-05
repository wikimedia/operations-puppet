# SPDX-License-Identifier: Apache-2.0
class profile::openstack::codfw1dev::keystone::fernet_keys(
    Array[OpenStack::ControlNode] $openstack_control_nodes = lookup('profile::openstack::codfw1dev::openstack_control_nodes'),
    String $cred_key_0 = lookup('profile::openstack::codfw1dev::keystone::credential_key_0'),
    String $cred_key_1 = lookup('profile::openstack::codfw1dev::keystone::credential_key_1'),
) {
    class {'profile::openstack::base::keystone::fernet_keys':
        openstack_control_nodes => $openstack_control_nodes,
        cred_key_0              => $cred_key_0,
        cred_key_1              => $cred_key_1,
    }
}
