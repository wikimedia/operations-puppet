class profile::openstack::codfw1dev::keystone::fernet_keys(
    Array[Stdlib::Fqdn] $openstack_controllers = lookup('profile::openstack::codfw1dev::openstack_controllers'),
    String $rotate_time = lookup('profile::openstack::codfw1dev::fernet_key_rotate_time'),
    String $sync_time = lookup('profile::openstack::codfw1dev::fernet_key_sync_time'),
    ) {
    class {'profile::openstack::base::keystone::fernet_keys':
        keystone_hosts => $openstack_controllers,
        rotate_time    => $rotate_time,
        sync_time      => $sync_time,
    }
}
