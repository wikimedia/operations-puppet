class profile::openstack::labtestn::glance(
    $version = hiera('profile::openstack::labtestn::version'),
    $nova_controller = hiera('profile::openstack::labtestn::nova_controller'),
    $nova_controller_standby = hiera('profile::openstack::labtestn::nova_controller_standby'),
    $db_pass = hiera('profile::openstack::labtestn::glance::db_pass'),
    $db_host = hiera('profile::openstack::labtestn::glance::db_host'),
    $ldap_user_pass = hiera('profile::openstack::labtestn::ldap_user_pass'),
    $labs_hosts_range = hiera('profile::openstack::labtestn::labs_hosts_range'),
    ) {

    require ::profile::openstack::labtestn::cloudrepo
    class {'::profile::openstack::base::glance':
        version                 => $version,
        nova_controller         => $nova_controller,
        nova_controller_standby => $nova_controller_standby,
        db_pass                 => $db_pass,
        db_host                 => $db_host,
        ldap_user_pass          => $ldap_user_pass,
        labs_hosts_range        => $labs_hosts_range,
    }
    contain '::profile::openstack::base::glance'
}
