class profile::openstack::labtest::glance(
    $version = hiera('profile::openstack::labtest::version'),
    $nova_controller = hiera('profile::openstack::labtest::nova_controller'),
    $nova_controller_standby = hiera('profile::openstack::labtest::nova_controller_standby'),
    $db_pass = hiera('profile::openstack::labtest::glance::db_pass'),
    $db_host = hiera('profile::openstack::labtest::glance::db_host'),
    $ldap_user_pass = hiera('profile::openstack::labtest::ldap_user_pass'),
    ) {

    require ::profile::openstack::labtest::cloudrepo
    class {'profile::openstack::base::glance':
        version                 => $version,
        nova_controller         => $nova_controller,
        nova_controller_standby => $nova_controller_standby,
        db_pass                 => $db_pass,
        db_host                 => $db_host,
        ldap_user_pass          => $ldap_user_pass,
    }

    class {'openstack2::glance::monitor':
        active => ($::fqdn == $nova_controller),
    }
}
