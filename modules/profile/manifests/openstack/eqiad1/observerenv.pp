class profile::openstack::eqiad1::observerenv(
    String       $region            = lookup('profile::openstack::eqiad1::region'),
    Stdlib::Fqdn $keystone_api_fqdn = lookup('profile::openstack::eqiad1::keystone_api_fqdn'),
    String       $observer_password = lookup('profile::openstack::eqiad1::observer_password'),
  ) {

    class {'::profile::openstack::base::observerenv':
        region            => $region,
        keystone_api_fqdn => $keystone_api_fqdn,
        os_password       => $observer_password,
    }
    contain '::profile::openstack::base::observerenv'
}
