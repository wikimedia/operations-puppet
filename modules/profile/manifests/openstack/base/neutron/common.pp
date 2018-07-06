class profile::openstack::base::neutron::common(
    $version = hiera('profile::openstack::base::version'),
    $region = hiera('profile::openstack::base::region'),
    $db_user = hiera('profile::openstack::base::neutron::db_user'),
    $db_pass = hiera('profile::openstack::base::neutron::db_pass'),
    $db_host = hiera('profile::openstack::base::neutron::db_host'),
    $nova_controller = hiera('profile::openstack::base::nova_controller'),
    $keystone_host = hiera('profile::openstack::base::keystone_host'),
    $ldap_user_pass = hiera('profile::openstack::base::ldap_user_pass'),
    $rabbit_user = hiera('profile::openstack::base::neutron::rabbit_user'),
    $rabbit_pass = hiera('profile::openstack::base::neutron::rabbit_pass'),
    $tld = hiera('profile::openstack::base::neutron::tld'),
    ) {

    class {'::openstack::neutron::common':
        version         => $version,
        nova_controller => $nova_controller,
        keystone_host   => $keystone_host,
        db_pass         => $db_pass,
        db_user         => $db_user,
        db_host         => $db_host,
        region          => $region,
        ldap_user_pass  => $ldap_user_pass,
        rabbit_pass     => $rabbit_pass,
        rabbit_user     => $rabbit_user,
        tld             => $tld,
    }
    contain '::openstack::neutron::common'
}
