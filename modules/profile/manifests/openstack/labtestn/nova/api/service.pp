class profile::openstack::labtestn::nova::api::service(
    $nova_api_host = hiera('profile::openstack::labtestn::nova_api_host'),
    ) {

    require profile::openstack::labtestn::nova::common
    class {'::openstack2::nova::api::service':
        active => $::fqdn == $nova_api_host,
    }
}
