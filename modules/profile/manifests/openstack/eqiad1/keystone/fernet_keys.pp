class profile::openstack::eqiad1::keystone::fernet_keys(
    Array[Stdlib::Fqdn] $openstack_controllers = lookup('profile::openstack::eqiad1::openstack_controllers'),
    ) {
    class {'profile::openstack::base::keystone::fernet_keys':
        keystone_hosts => $openstack_controllers,
    }
}
