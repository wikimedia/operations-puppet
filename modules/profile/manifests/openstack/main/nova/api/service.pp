class profile::openstack::main::nova::api::service(
    $nova_api_host = hiera('profile::openstack::main::nova_api_host'),
    ) {

    require profile::openstack::main::nova::common
    class {'::openstack2::nova::api::service':
        active => ($::fqdn == $nova_api_host),
    }
}
