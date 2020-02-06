class profile::openstack::eqiad1::keystone::fernet_keys(
    Stdlib::Fqdn $nova_controller = lookup('profile::openstack::eqiad1::nova_controller'),
    Stdlib::Fqdn $nova_controller_standby = lookup('profile::openstack::eqiad1::nova_controller_standby'),
    String $rotate_time = lookup('profile::openstack::eqiad1::fernet_key_rotate_time'),
    String $sync_time = lookup('profile::openstack::eqiad1::fernet_key_sync_time'),
    ) {
    class {'profile::openstack::base::keystone::fernet_keys':
        keystone_hosts => [$nova_controller, $nova_controller_standby],
        rotate_time    => $rotate_time,
        sync_time      => $rotate_time,
    }
}
