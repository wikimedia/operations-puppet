class profile::openstack::base::nova::api::service(
    $nova_api_host = hiera('profile::openstack::base::nova_api_host'),
    ) {

    class {'::openstack2::nova::api::service':
        active => ($::fqdn == $nova_api_host),
    }
}
