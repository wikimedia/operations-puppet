class profile::openstack::labtest::nodepool::service(
    $nova_controller = hiera('profile::openstack::labtest::nova_controller'),
    ) {

    class {'::profile::openstack::base::nodepool::service':
        nova_controller => $nova_controller,
    }

    class {'::profile::openstack::base::nodepool::monitor':}
}
