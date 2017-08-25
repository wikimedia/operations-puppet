class profile::openstack::main::glance(
    $version = hiera('profile::openstack::main::version'),
    $nova_controller = hiera('profile::openstack::main::nova_controller'),
    $nova_controller_standby = hiera('profile::openstack::main::nova_controller_standby'),
    $db_pass = hiera('profile::openstack::main::glance::db_pass'),
    $db_host = hiera('profile::openstack::main::glance::db_host'),
    $ldap_user_pass = hiera('profile::openstack::main::ldap_user_pass'),
    $glance_image_dir = hiera('profile::openstack::base::glance::image_dir'),
    $labs_hosts_range = hiera('profile::openstack::main::labs_hosts_range'),
    ) {

    require ::profile::openstack::main::cloudrepo
    class {'profile::openstack::base::glance':
        version                 => $version,
        nova_controller         => $nova_controller,
        nova_controller_standby => $nova_controller_standby,
        db_pass                 => $db_pass,
        db_host                 => $db_host,
        ldap_user_pass          => $ldap_user_pass,
        labs_hosts_range        => $labs_hosts_range,
    }

    class {'openstack2::glance::image_sync':
        active                  => ($::fqdn == $nova_controller),
        version                 => $version,
        glance_image_dir        => $glance_image_dir,
        nova_controller_standby => $nova_controller_standby,
    }

    class {'openstack2::glance::monitor':
        active => ($::fqdn == $nova_controller),
    }
}
