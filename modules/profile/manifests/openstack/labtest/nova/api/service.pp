class profile::openstack::labtest::nova::api::service(
    $nova_api_host = hiera('profile::openstack::labtest::nova_api_host'),
    ) {

    require ::profile::openstack::labtest::nova::common
    class {'::profile::openstack::base::nova::api::service':
        nova_api_host => $nova_api_host,
    }
    contain '::profile::openstack::base::nova::api::service'
}
