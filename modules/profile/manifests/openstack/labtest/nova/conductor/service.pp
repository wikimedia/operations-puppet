class profile::openstack::labtest::nova::conductor::service(
    $nova_controller = hiera('profile::openstack::labtest::nova_controller'),
    ) {

    require ::profile::openstack::labtest::nova::common
    class {'::openstack2::nova::conductor::service':
        active => ($::fqdn == $nova_controller),
    }
}
