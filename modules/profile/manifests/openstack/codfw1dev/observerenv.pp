class profile::openstack::codfw1dev::observerenv(
    $region = hiera('profile::openstack::codfw1dev::region'),
    $keystone_host = hiera('profile::openstack::codfw1dev::keystone_host'),
    $observer_password = hiera('profile::openstack::codfw1dev::observer_password'),
  ) {

    require ::profile::openstack::codfw1dev::clientpackages
    class {'::profile::openstack::base::observerenv':
        region            => $region,
        keystone_host     => $keystone_host,
        observer_password => $observer_password,
    }
    contain '::profile::openstack::base::observerenv'
}
