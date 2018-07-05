class profile::openstack::eqiad1::glance (
    $version = hiera('profile::openstack::eqiad1::version'),
    $nova_controller = hiera('profile::openstack::eqiad1::nova_controller'),
    $keystone_host = hiera('profile::openstack::eqiad1::keystone_host'),
    $nova_controller_standby = hiera('profile::openstack::eqiad1::nova_controller_standby'),
    $db_pass = hiera('profile::openstack::eqiad1::glance::db_pass'),
    $db_host = hiera('profile::openstack::eqiad1::glance::db_host'),
    $ldap_user_pass = hiera('profile::openstack::eqiad1::ldap_user_pass'),
    $labs_hosts_range = hiera('profile::openstack::eqiad1::labs_hosts_range'),
    ) {

    require ::profile::openstack::eqiad1::clientlib
    class {'::profile::openstack::base::glance':
        version                 => $version,
        nova_controller         => $nova_controller,
        nova_controller_standby => $nova_controller_standby,
        keystone_host           => $keystone_host,
        db_pass                 => $db_pass,
        db_host                 => $db_host,
        ldap_user_pass          => $ldap_user_pass,
        labs_hosts_range        => $labs_hosts_range,
    }
    contain '::profile::openstack::base::glance'
}
