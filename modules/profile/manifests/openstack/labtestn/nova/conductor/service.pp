class profile::openstack::labtestn::nova::conductor::service(
    $nova_controller = hiera('profile::openstack::labtestn::nova_controller'),
    ) {

    require ::profile::openstack::labtestn::nova::common
    class {'::profile::openstack::base::nova::conductor::service':
        nova_controller => $nova_controller,
    }
}
