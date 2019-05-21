class profile::openstack::eqiad1::nova::common(
    $version = hiera('profile::openstack::eqiad1::version'),
    $db_pass = hiera('profile::openstack::eqiad1::nova::db_pass'),
    $db_host = hiera('profile::openstack::eqiad1::nova::db_host'),
    $db_name = hiera('profile::openstack::eqiad1::nova::db_name'),
    $db_name_api = hiera('profile::openstack::eqiad1::nova::db_name_api'),
    $nova_controller = hiera('profile::openstack::eqiad1::nova_controller'),
    $nova_controller_standby = hiera('profile::openstack::eqiad1::nova_controller_standby'),
    $keystone_host = hiera('profile::openstack::eqiad1::keystone_host'),
    $glance_host = hiera('profile::openstack::eqiad1::glance_host'),
    $scheduler_pool = hiera('profile::openstack::eqiad1::nova::scheduler_pool'),
    $ldap_user_pass = hiera('profile::openstack::eqiad1::ldap_user_pass'),
    $rabbit_pass = hiera('profile::openstack::eqiad1::nova::rabbit_pass'),
    $metadata_proxy_shared_secret = hiera('profile::openstack::eqiad1::neutron::metadata_proxy_shared_secret')
    ) {

    require ::profile::openstack::eqiad1::clientpackages
    class {'::profile::openstack::base::nova::common::neutron':
        version                      => $version,
        db_pass                      => $db_pass,
        db_host                      => $db_host,
        db_name                      => $db_name,
        db_name_api                  => $db_name_api,
        nova_controller              => $nova_controller,
        nova_controller_standby      => $nova_controller_standby,
        keystone_host                => $keystone_host,
        glance_host                  => $glance_host,
        scheduler_pool               => $scheduler_pool,
        ldap_user_pass               => $ldap_user_pass,
        rabbit_pass                  => $rabbit_pass,
        metadata_proxy_shared_secret => $metadata_proxy_shared_secret,
    }
    contain '::profile::openstack::base::nova::common::neutron'
}
