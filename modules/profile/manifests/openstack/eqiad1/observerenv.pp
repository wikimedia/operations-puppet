class profile::openstack::eqiad1::observerenv(
    String       $region            = lookup('profile::openstack::eqiad1::region'),
    Stdlib::Fqdn $keystone_host     = lookup('profile::openstack::eqiad1::keystone_host'),
    String       $observer_password = lookup('profile::openstack::eqiad1::observer_password'),
  ) {

    class {'::profile::openstack::base::observerenv':
        region            => $region,
        keystone_host     => $keystone_host,
        observer_password => $observer_password,
    }
    contain '::profile::openstack::base::observerenv'
}
