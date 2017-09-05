class profile::openstack::labtest::glance(
    $version = hiera('profile::openstack::labtest::version'),
    $nova_controller = hiera('profile::openstack::labtest::nova_controller'),
    $nova_controller_standby = hiera('profile::openstack::labtest::nova_controller_standby'),
    $db_pass = hiera('profile::openstack::labtest::glance::db_pass'),
    $db_host = hiera('profile::openstack::labtest::glance::db_host'),
    $ldap_user_pass = hiera('profile::openstack::labtest::ldap_user_pass'),
    $labs_hosts_range = hiera('profile::openstack::labtest::labs_hosts_range'),
    ) {

    require ::profile::openstack::labtest::cloudrepo
    class {'profile::openstack::base::glance':
        version                 => $version,
        nova_controller         => $nova_controller,
        nova_controller_standby => $nova_controller_standby,
        db_pass                 => $db_pass,
        db_host                 => $db_host,
        ldap_user_pass          => $ldap_user_pass,
        labs_hosts_range        => $labs_hosts_range,
    }

    class {'openstack2::glance::monitor':
        active => ($::fqdn == $nova_controller),
    }
}
