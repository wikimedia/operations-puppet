class profile::openstack::labtestn::observerenv(
    $region = hiera('profile::openstack::labtestn::region'),
    $keystone_host = hiera('profile::openstack::labtestn::keystone_host'),
    $observer_password = hiera('profile::openstack::labtestn::observer_password'),
  ) {

    require ::profile::openstack::labtestn::clientpackages
    class {'::profile::openstack::base::observerenv':
        region            => $region,
        keystone_host     => $keystone_host,
        observer_password => $observer_password,
    }
    contain '::profile::openstack::base::observerenv'
}
