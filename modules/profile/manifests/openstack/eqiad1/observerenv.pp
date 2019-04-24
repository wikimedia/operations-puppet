class profile::openstack::eqiad1::observerenv(
    $region = hiera('profile::openstack::eqiad1::region'),
    $keystone_host = hiera('profile::openstack::eqiad1::keystone_host'),
    $observer_password = hiera('profile::openstack::eqiad1::observer_password'),
  ) {

    class {'::profile::openstack::base::observerenv':
        region            => $region,
        keystone_host     => $keystone_host,
        observer_password => $observer_password,
    }
    contain '::profile::openstack::base::observerenv'
}
