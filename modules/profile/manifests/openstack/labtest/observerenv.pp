class profile::openstack::labtest::observerenv(
    $keystone_host = hiera('profile::openstack::labtest::keystone_host'),
    $observer_password = hiera('profile::openstack::labtest::observer_password'),
  ) {

    class {'::profile::openstack::base::observerenv':
        keystone_host     => $keystone_host ,
        observer_password => $observer_password,
    }
    contain '::profile::openstack::base::observerenv'
}
