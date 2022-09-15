class profile::openstack::codfw1dev::keystone::fernet_keys(
    Array[Stdlib::Fqdn] $openstack_controllers = lookup('profile::openstack::codfw1dev::openstack_controllers'),
    ) {
    class {'profile::openstack::base::keystone::fernet_keys':
        keystone_hosts => $openstack_controllers,
    }
}
