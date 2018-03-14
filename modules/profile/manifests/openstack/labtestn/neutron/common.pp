class profile::openstack::labtestn::neutron::common {
    $version = hiera('profile::openstack::labtestn::version'),
    $region = hiera('profile::openstack::labtestn::region'),
    $db_pass = hiera('profile::openstack::labtestn::neutron::db_pass'),
    $db_host = hiera('profile::openstack::labtestn::neutron::db_host'),
    $nova_controller = hiera('profile::openstack::labtestn::nova_controller'),
    $ldap_user_pass = hiera('profile::openstack::labtestn::ldap_user_pass'),
    $rabbit_pass = hiera('profile::openstack::labtestn::neutron::rabbit_pass'),
    ) {

    require ::profile::openstack::labtestn::clientlib
    class {'::profile::openstack::base::neutron::common':
        version         => $version,
        nova_controller => $nova_controller,
        db_pass         => $db_pass,
        db_host         => $db_host,
        region          => $region,
        ldap_user_pass  => $ldap_user_pass,
        rabbit_pass     => $rabbit_pass,
    }
    contain '::profile::openstack::base::neutron::common'
}
