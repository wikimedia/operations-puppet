class profile::openstack::main::observerenv(
    $keystone_host = hiera('profile::openstack::main::keystone_host'),
    $observer_password = hiera('profile::openstack::main::observer_password'),
  ) {

    class {'profile::openstack::base::observerenv':
        keystone_host     => $keystone_host,
        observer_password => $observer_password,
    }
}
