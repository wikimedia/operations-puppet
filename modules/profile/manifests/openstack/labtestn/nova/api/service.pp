class profile::openstack::labtestn::nova::api::service(
    $nova_api_host = hiera('profile::openstack::labtestn::nova_api_host'),
    ) {

    require ::profile::openstack::labtestn::nova::common
    class {'profile::openstack::base::nova::api::service':
        nova_api_host => $nova_api_host,
    }
}
