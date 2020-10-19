class profile::openstack::eqiad1::glance (
    String $version = lookup('profile::openstack::eqiad1::version'),
    Array[Stdlib::Fqdn] $openstack_controllers = lookup('profile::openstack::eqiad1::openstack_controllers'),
    Stdlib::Fqdn $keystone_fqdn = lookup('profile::openstack::eqiad1::keystone_api_fqdn'),
    String $db_pass = lookup('profile::openstack::eqiad1::glance::db_pass'),
    Stdlib::Fqdn $db_host = lookup('profile::openstack::eqiad1::glance::db_host'),
    String $ldap_user_pass = lookup('profile::openstack::eqiad1::ldap_user_pass'),
    Stdlib::Absolutepath $glance_image_dir = lookup('profile::openstack::base::glance::image_dir'),
    Stdlib::Port $api_bind_port = lookup('profile::openstack::eqiad1::glance::api_bind_port'),
    Stdlib::Port $registry_bind_port = lookup('profile::openstack::eqiad1::glance::registry_bind_port'),
    Stdlib::Fqdn $primary_glance_image_store = lookup('profile::openstack::eqiad1::primary_glance_image_store'),
    Array[String] $glance_backends = lookup('profile::openstack::eqiad1::glance_backends'),
    ) {

    require ::profile::openstack::eqiad1::clientpackages
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
        glance_backends            => $glance_backends,
    }
    contain '::profile::openstack::base::glance'

    class {'openstack::glance::monitor':
        active         => ($::fqdn == $primary_glance_image_store),
        contact_groups => 'wmcs-team,admins',
    }
}
