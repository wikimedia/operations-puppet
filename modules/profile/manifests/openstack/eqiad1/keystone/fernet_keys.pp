class profile::openstack::eqiad1::keystone::fernet_keys(
    Array[OpenStack::ControlNode] $openstack_control_nodes = lookup('profile::openstack::eqiad1::openstack_control_nodes'),
) {
    class {'profile::openstack::base::keystone::fernet_keys':
        openstack_control_nodes => $openstack_control_nodes,
    }
}
