class profile::openstack::base::nova::common::neutron(
    $version = hiera('profile::openstack::base::version'),
    $db_user = hiera('profile::openstack::base::nova::db_user'),
    $db_pass = hiera('profile::openstack::base::nova::db_pass'),
    $db_host = hiera('profile::openstack::base::nova::db_host'),
    $db_name = hiera('profile::openstack::base::nova::db_name'),
    $nova_controller = hiera('profile::openstack::base::nova_controller'),
    $ldap_user_pass = hiera('profile::openstack::base::ldap_user_pass'),
    $rabbit_user = hiera('profile::openstack::base::nova::rabbit_user'),
    $rabbit_pass = hiera('profile::openstack::base::rabbit_pass'),
    ) {

    class {'::openstack::nova::common::neutron':
        version         => $version,
        db_user         => $db_user,
        db_pass         => $db_pass,
        db_host         => $db_host,
        db_name         => $db_name,
        nova_controller => $nova_controller,
        ldap_user_pass  => $ldap_user_pass,
        rabbit_user     => $rabbit_user,
        rabbit_host     => $nova_controller,
        rabbit_pass     => $rabbit_pass,
        glance_host     => $nova_controller,
    }
    contain '::openstack::nova::common::neutron'
}
