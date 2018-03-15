class profile::openstack::labtestn::nova::common(
    $version = hiera('profile::openstack::labtestn::version'),
    $db_pass = hiera('profile::openstack::labtestn::nova::db_pass'),
    $db_host = hiera('profile::openstack::labtestn::nova::db_host'),
    $nova_controller = hiera('profile::openstack::labtestn::nova_controller'),
    $ldap_user_pass = hiera('profile::openstack::labtestn::ldap_user_pass'),
    $rabbit_pass = hiera('profile::openstack::labtestn::nova::rabbit_pass'),
    $metadata_proxy_shared_secret = hiera('profile::openstack::labtestn::neutron::metadata_proxy_shared_secret')
    ) {

    require ::profile::openstack::labtestn::clientlib
    class {'::profile::openstack::base::nova::common::neutron':
        version                      => $version,
        db_pass                      => $db_pass,
        db_host                      => $db_host,
        nova_controller              => $nova_controller,
        ldap_user_pass               => $ldap_user_pass,
        rabbit_pass                  => $rabbit_pass,
        metadata_proxy_shared_secret => $metadata_proxy_shared_secret,
    }
    contain '::profile::openstack::base::nova::common::neutron'
}
