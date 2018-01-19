class profile::openstack::base::nova::common::neutron(
    $version = hiera('profile::openstack::base::version'),
    ) {

    class {'::openstack::nova::common::neutron':
        version                  => $version,
    }
    contain '::openstack::nova::common::neutron'
}
