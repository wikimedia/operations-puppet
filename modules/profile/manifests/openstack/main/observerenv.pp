class profile::openstack::main::observerenv(
    $nova_controller = hiera('profile::openstack::main::nova_controller'),
    $observer_password = hiera('profile::openstack::main::observer_password'),
  ) {

    class {'profile::openstack::base::observerenv':
        nova_controller   => $nova_controller ,
        observer_password => $observer_password,
    }
}
