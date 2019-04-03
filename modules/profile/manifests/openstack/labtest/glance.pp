class profile::openstack::labtest::glance(
    $version = hiera('profile::openstack::labtest::version'),
    $nova_controller = hiera('profile::openstack::labtest::nova_controller'),
    $keystone_host = hiera('profile::openstack::labtest::keystone_host'),
    $nova_controller_standby = hiera('profile::openstack::labtest::nova_controller_standby'),
    $labtestn_nova_controller = hiera('profile::openstack::labtestn::nova_controller'),
    $db_pass = hiera('profile::openstack::labtest::glance::db_pass'),
    $db_host = hiera('profile::openstack::labtest::glance::db_host'),
    $ldap_user_pass = hiera('profile::openstack::labtest::ldap_user_pass'),
    $labs_hosts_range = hiera('profile::openstack::labtest::labs_hosts_range'),
    ) {

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

    class {'::openstack::glance::monitor':
        active => ($::fqdn == $nova_controller),
    }
    contain '::openstack::glance::monitor'
}
