class profile::openstack::labtest::nova::api::service(
    $nova_api_host = hiera('profile::openstack::labtest::nova_api_host'),
    ) {

    require ::profile::openstack::labtest::nova::common
    class {'::openstack2::nova::api::service':
        active => $::fqdn == $nova_api_host,
    }
}
