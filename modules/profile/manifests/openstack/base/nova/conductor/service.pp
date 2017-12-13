class profile::openstack::base::nova::conductor::service(
    $nova_controller = hiera('profile::openstack::base::nova_controller'),
    ) {

    class {'::openstack::nova::conductor::service':
        active => $::fqdn == $nova_controller,
    }
    contain '::openstack::nova::conductor::service'
}
