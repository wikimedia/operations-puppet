class profile::openstack::labtest::nova::conductor::service(
    $nova_controller = hiera('profile::openstack::labtest::nova_controller'),
    ) {

    require ::profile::openstack::labtest::nova::common
    class {'::profile::openstack::base::nova::conductor::service':
        nova_controller => $nova_controller,
    }
    contain '::profile::openstack::base::nova::conductor::service'
}
