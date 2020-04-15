class profile::openstack::eqiad1::glance (
    $version = hiera('profile::openstack::eqiad1::version'),
    Array[Stdlib::Fqdn] $openstack_controllers = lookup('profile::openstack::eqiad1::openstack_controllers'),
    $keystone_host = hiera('profile::openstack::eqiad1::keystone_host'),
    $db_pass = hiera('profile::openstack::eqiad1::glance::db_pass'),
    $db_host = hiera('profile::openstack::eqiad1::glance::db_host'),
    $ldap_user_pass = hiera('profile::openstack::eqiad1::ldap_user_pass'),
    $glance_image_dir = hiera('profile::openstack::base::glance::image_dir'),
    Stdlib::Port $api_bind_port = lookup('profile::openstack::eqiad1::glance::api_bind_port'),
    Stdlib::Port $registry_bind_port = lookup('profile::openstack::eqiad1::glance::registry_bind_port'),
    Stdlib::Fqdn $primary_glance_image_store = lookup('profile::openstack::eqiad1::primary_glance_image_store'),
    ) {

    require ::profile::openstack::eqiad1::clientpackages
    class {'::profile::openstack::base::glance':
        version                    => $version,
        openstack_controllers      => $openstack_controllers,
        keystone_host              => $keystone_host,
        db_pass                    => $db_pass,
        db_host                    => $db_host,
        ldap_user_pass             => $ldap_user_pass,
        api_bind_port              => $api_bind_port,
        registry_bind_port         => $registry_bind_port,
        primary_glance_image_store => $primary_glance_image_store,
    }
    contain '::profile::openstack::base::glance'

    class {'openstack::glance::monitor':
        active         => ($::fqdn == $primary_glance_image_store),
        contact_groups => 'wmcs-team,admins',
    }
}
