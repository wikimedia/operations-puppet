class profile::openstack::codfw1dev::observerenv(
    String       $region            = lookup('profile::openstack::codfw1dev::region'),
    Stdlib::Fqdn $keystone_api_fqdn = lookup('profile::openstack::codfw1dev::keystone_api_fqdn'),
    String       $observer_password = lookup('profile::openstack::codfw1dev::observer_password'),
  ) {

    class {'::profile::openstack::base::observerenv':
        region            => $region,
        keystone_api_fqdn => $keystone_api_fqdn,
        os_password       => $observer_password,
    }
    contain '::profile::openstack::base::observerenv'
}
