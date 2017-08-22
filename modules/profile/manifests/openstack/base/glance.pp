class profile::openstack::base::glance(
    $version = hiera('profile::openstack::base::version'),
    $nova_controller = hiera('profile::openstack::base::nova_controller'),
    $nova_controller_standby = hiera('profile::openstack::base::nova_controller_stanbdy'),
    $auth_port = hiera('profile::openstack::base::keystone::auth_port'),
    $public_port = hiera('profile::openstack::base::keystone::public_port'),
    $db_user = hiera('profile::openstack::base::glance::db_user'),
    $db_name = hiera('profile::openstack::base::glance::db_name'),
    $db_pass = hiera('profile::openstack::base::glance::db_pass'),
    $db_host = hiera('profile::openstack::base::glance::db_host'),
    $ldap_user_pass = hiera('profile::openstack::base::ldap_user_pass'),
    $glance_data = hiera('profile::openstack::base::glance::data_dir'),
    $glance_image_dir = hiera('profile::openstack::base::glance::image_dir'),
    ) {

    $keystone_admin_uri = "http://${nova_controller}:${auth_port}"
    $keystone_public_uri = "http://${nova_controller}:${public_port}"
    $nova_controller_ip  = ipresolve($nova_controller,4)

    class { 'openstack2::glance::service':
        version                 => $version,
        active                  => $::fqdn == $nova_controller,
        nova_controller_ip      => $nova_controller_ip,
        keystone_admin_uri      => $keystone_admin_uri,
        keystone_public_uri     => $keystone_public_uri,
        db_user                 => db_user,
        db_pass                 => db_pass,
        db_name                 => db_name,
        db_host                 => db_host,
        ldap_user_pass          => $ldap_user_pass,
        nova_controller_standby => $nova_controller_standby,
        glance_data             => $glance_data,
        glance_image_dir        => $glance_image_dir,
    }
}
