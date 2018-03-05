class profile::openstack::labtestn::observerenv(
    $region = heira('profile::openstack::labtestn::region'),
    $nova_controller = hiera('profile::openstack::labtestn::nova_controller'),
    $observer_password = hiera('profile::openstack::labtestn::observer_password'),
  ) {

    require ::profile::openstack::labtestn::clientlib
    class {'::profile::openstack::base::observerenv':
        region            => $region,
        nova_controller   => $nova_controller,
        observer_password => $observer_password,
    }
    contain '::profile::openstack::base::observerenv'
}
