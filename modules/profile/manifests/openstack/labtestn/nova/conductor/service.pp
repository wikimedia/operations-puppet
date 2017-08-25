class profile::openstack::labtestn::nova::conductor::service(
    $nova_controller = hiera('profile::openstack::labtestn::nova_controller'),
    ) {

    require profile::openstack::labtestn::nova::common
    class {'::openstack2::nova::conductor::service':
        active => $::fqdn == $nova_controller,
    }
}
