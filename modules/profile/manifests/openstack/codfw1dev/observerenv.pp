class profile::openstack::codfw1dev::observerenv(
    String       $region            = lookup('profile::openstack::codfw1dev::region'),
    Stdlib::Fqdn $keystone_host     = lookup('profile::openstack::codfw1dev::keystone_host'),
    String       $observer_password = lookup('profile::openstack::codfw1dev::observer_password'),
  ) {

    class {'::profile::openstack::base::observerenv':
        region            => $region,
        keystone_host     => $keystone_host,
        observer_password => $observer_password,
    }
    contain '::profile::openstack::base::observerenv'
}
