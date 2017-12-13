class profile::openstack::labtest::observerenv(
    $nova_controller = hiera('profile::openstack::labtest::nova_controller'),
    $observer_password = hiera('profile::openstack::labtest::observer_password'),
  ) {

    class {'::profile::openstack::base::observerenv':
        nova_controller   => $nova_controller ,
        observer_password => $observer_password,
    }
    contain '::profile::openstack::base::observerenv'
}
