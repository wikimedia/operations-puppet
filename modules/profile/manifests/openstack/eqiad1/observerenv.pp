class profile::openstack::eqiad1::observerenv(
    $region = hiera('profile::openstack::eqiad1::region'),
    $nova_controller = hiera('profile::openstack::eqiad1::nova_controller'),
    $observer_password = hiera('profile::openstack::eqiad1::observer_password'),
  ) {

    require ::profile::openstack::eqiad1::clientlib
    class {'::profile::openstack::base::observerenv':
        region            => $region,
        nova_controller   => $nova_controller,
        observer_password => $observer_password,
    }
    contain '::profile::openstack::base::observerenv'
}
