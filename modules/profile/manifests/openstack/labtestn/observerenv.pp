class profile::openstack::labtestn::observerenv(
    $nova_controller = hiera('profile::openstack::labtestn::nova_controller'),
    $observer_password = hiera('profile::openstack::labtestn::observer_password'),
  ) {

    class {'::profile::openstack::base::observerenv':
        nova_controller   => $nova_controller,
        observer_password => $observer_password,
    }
    contain '::profile::openstack::base::observerenv'
}
