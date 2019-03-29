class profile::openstack::codfw1dev::glance(
    $version = hiera('profile::openstack::codfw1dev::version'),
    $nova_controller = hiera('profile::openstack::codfw1dev::nova_controller'),
    $keystone_host = hiera('profile::openstack::codfw1dev::keystone_host'),
    $nova_controller_standby = hiera('profile::openstack::codfw1dev::nova_controller_standby'),
    $db_pass = hiera('profile::openstack::codfw1dev::glance::db_pass'),
    $db_host = hiera('profile::openstack::codfw1dev::glance::db_host'),
    $ldap_user_pass = hiera('profile::openstack::codfw1dev::ldap_user_pass'),
    $labs_hosts_range = hiera('profile::openstack::codfw1dev::labs_hosts_range'),
    ) {

    require ::profile::openstack::codfw1dev::clientpackages
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
