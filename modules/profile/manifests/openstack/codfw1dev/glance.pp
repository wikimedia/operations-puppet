class profile::openstack::codfw1dev::glance(
    $version = hiera('profile::openstack::codfw1dev::version'),
    Array[Stdlib::Fqdn] $openstack_controllers = lookup('profile::openstack::codfw1dev::openstack_controllers'),
    Stdlib::Fqdn $keystone_fqdn = lookup('profile::openstack::codfw1dev::keystone_api_fqdn'),
    $db_pass = hiera('profile::openstack::codfw1dev::glance::db_pass'),
    $db_host = hiera('profile::openstack::codfw1dev::glance::db_host'),
    $ldap_user_pass = hiera('profile::openstack::codfw1dev::ldap_user_pass'),
    $glance_image_dir = hiera('profile::openstack::base::glance::image_dir'),
    Stdlib::Port $api_bind_port = lookup('profile::openstack::codfw1dev::glance::api_bind_port'),
    Stdlib::Port $registry_bind_port = lookup('profile::openstack::codfw1dev::glance::registry_bind_port'),
    Stdlib::Fqdn $primary_glance_image_store = lookup('profile::openstack::codfw1dev::primary_glance_image_store'),
    ) {

    class {'::profile::openstack::base::glance':
        version                    => $version,
        openstack_controllers      => $openstack_controllers,
        keystone_fqdn              => $keystone_fqdn,
        db_pass                    => $db_pass,
        db_host                    => $db_host,
        ldap_user_pass             => $ldap_user_pass,
        api_bind_port              => $api_bind_port,
        registry_bind_port         => $registry_bind_port,
        primary_glance_image_store => $primary_glance_image_store,
    }
    contain '::profile::openstack::base::glance'
}
