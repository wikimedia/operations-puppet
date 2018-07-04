class profile::openstack::eqiad1::nova::api::service(
    $version = hiera('profile::openstack::eqiad1::version'),
    $nova_api_host = hiera('profile::openstack::eqiad1::nova_api_host'),
    ) {

    require ::profile::openstack::eqiad1::nova::common
    class {'profile::openstack::base::nova::api::service':
        version       => $version,
        nova_api_host => $nova_api_host,
    }
}
