class profile::openstack::main::nova::conductor::service(
    $nova_controller = hiera('profile::openstack::main::nova_controller'),
    ) {

    require profile::openstack::main::nova::common
    class {'::openstack2::nova::conductor::service':
        active => ($::fqdn == $nova_controller),
    }
}
