class profile::openstack::eqiad1::keystone::fernet_keys(
    Array[OpenStack::ControlNode] $openstack_control_nodes = lookup('profile::openstack::eqiad1::openstack_control_nodes'),
    String $cred_key_0 = lookup('profile::openstack::eqiad1::keystone::credential_key_0'),
    String $cred_key_1 = lookup('profile::openstack::eqiad1::keystone::credential_key_1'),
) {
    class {'profile::openstack::base::keystone::fernet_keys':
        openstack_control_nodes => $openstack_control_nodes,
        cred_key_0              => $cred_key_0,
        cred_key_1              => $cred_key_1,
    }
}
