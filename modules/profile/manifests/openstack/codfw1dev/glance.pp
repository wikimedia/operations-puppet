class profile::openstack::codfw1dev::glance(
    $version = hiera('profile::openstack::codfw1dev::version'),
    $nova_controller = hiera('profile::openstack::codfw1dev::nova_controller'),
    $keystone_host = hiera('profile::openstack::codfw1dev::keystone_host'),
    $nova_controller_standby = hiera('profile::openstack::codfw1dev::nova_controller_standby'),
    $db_pass = hiera('profile::openstack::codfw1dev::glance::db_pass'),
    $db_host = hiera('profile::openstack::codfw1dev::glance::db_host'),
    $ldap_user_pass = hiera('profile::openstack::codfw1dev::ldap_user_pass'),
    $labs_hosts_range = hiera('profile::openstack::codfw1dev::labs_hosts_range'),
    $glance_image_dir = hiera('profile::openstack::base::glance::image_dir'),
    Stdlib::Port $api_bind_port = lookup('profile::openstack::codfw1dev::glance::api_bind_port'),
    Stdlib::Port $registry_bind_port = lookup('profile::openstack::codfw1dev::glance::registry_bind_port'),
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
        api_bind_port           => $api_bind_port,
        registry_bind_port      => $registry_bind_port,
    }
    contain '::profile::openstack::base::glance'

    class {'openstack::glance::image_sync':
        active                  => ($::fqdn == $nova_controller),
        glance_image_dir        => $glance_image_dir,
        nova_controller_standby => $nova_controller_standby,
    }
}
