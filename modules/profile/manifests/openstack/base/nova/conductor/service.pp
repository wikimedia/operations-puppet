class profile::openstack::base::nova::conductor::service(
    $nova_controller = hiera('profile::openstack::base::nova_controller'),
    ) {

    class {'::openstack2::nova::conductor::service':
        active => $::fqdn == $nova_controller,
    }
}
