class profile::openstack::eqiad1::neutron::common(
    $version = hiera('profile::openstack::eqiad1::version'),
    $region = hiera('profile::openstack::eqiad1::region'),
    $db_pass = hiera('profile::openstack::eqiad1::neutron::db_pass'),
    $nova_controller = hiera('profile::openstack::eqiad1::nova_controller'),
    $keystone_host = hiera('profile::openstack::eqiad1::keystone_host'),
    $ldap_user_pass = hiera('profile::openstack::eqiad1::ldap_user_pass'),
    $rabbit_pass = hiera('profile::openstack::eqiad1::neutron::rabbit_pass'),
    ) {

    require ::profile::openstack::eqiad1::clientlib
    class {'::profile::openstack::base::neutron::common':
        version         => $version,
        nova_controller => $nova_controller,
        keystone_host   => $keystone_host,
        db_pass         => $db_pass,
        db_host         => $nova_controller,
        region          => $region,
        ldap_user_pass  => $ldap_user_pass,
        rabbit_pass     => $rabbit_pass,
    }
    contain '::profile::openstack::base::neutron::common'
}
