class profile::openstack::labtestn::nova::api::service(
    $version = hiera('profile::openstack::labtestn::version'),
    $nova_api_host = hiera('profile::openstack::labtestn::nova_api_host'),
    ) {

    require ::profile::openstack::labtestn::nova::common
    class {'profile::openstack::base::nova::api::service':
        version       => $version,
        nova_api_host => $nova_api_host,
    }
}
