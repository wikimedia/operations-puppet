class profile::openstack::codfw1dev::keystone::fernet_keys(
    Stdlib::Fqdn $nova_controller = lookup('profile::openstack::codfw1dev::nova_controller'),
    Stdlib::Fqdn $nova_controller_standby = lookup('profile::openstack::codfw1dev::nova_controller_standby'),
    String $rotate_time = lookup('profile::openstack::codfw1dev::fernet_key_rotate_time'),
    String $sync_time = lookup('profile::openstack::codfw1dev::fernet_key_sync_time'),
    ) {
    class {'profile::openstack::base::keystone::fernet_keys':
        keystone_hosts => [$nova_controller, $nova_controller_standby],
        rotate_time    => $rotate_time,
        sync_time      => $rotate_time,
    }
}
