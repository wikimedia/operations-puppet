class profile::openstack::main::keystone::service(
    $version = hiera('profile::openstack::main::version'),
    $nova_controller = hiera('profile::openstack::main::nova_controller'),
    $keystone_host = hiera('profile::openstack::main::keystone_host'),
    $nova_db_pass = hiera('profile::openstack::main::nova::db_pass'),
    $ldap_user_pass = hiera('profile::openstack::main::ldap_user_pass'),
    $region = hiera('profile::openstack::main::region'),
    ) {

    require ::profile::openstack::main::clientpackages

    class {'::openstack::util::admin_scripts':
        version => $version,
    }
    contain '::openstack::util::admin_scripts'
}
