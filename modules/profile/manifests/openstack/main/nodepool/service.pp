class profile::openstack::main::nodepool::service(
    $nova_controller = hiera('profile::openstack::main::nova_controller'),
    ) {

    class {'::profile::openstack::base::nodepool::service':
        nova_controller => $nova_controller,
    }

    class {'::profile::openstack::base::nodepool::monitor':}
}
